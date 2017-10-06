#
# SpectrumController#search() - primary entry point for searches against
# Summon or GoogleAppliance, or for any Aggregate searches
#   - figures out the sources, then for each one calls:
#     SpectrumController#get_results()
#     - which for each source
#       - fixes input parameters in a source-specific way,
#       - calls either:  Spectrum::SearchEngines::Summon.new(fixed_params)
#       -           or:  blacklight_search(fixed_params)
#
# SpectrumController#searchjson() - alternative entry point
#   - does the same thing, but for AJAX calls, returning JSON
#
class SpectrumController < ApplicationController
  # done in ApplicationController
  # include Blacklight::Controller
  # include Blacklight::Catalog
  # include Blacklight::Configurable

  layout 'quicksearch'

  def search

# raise
    @results = []

    # process any Filter Queries - turn Summon API Array of key:value pairs into
    # nested Rails hash (see inverse transform in Spectrum::SearchEngines::Summon)
    #  BEFORE: params[s.fq]="AuthorCombined:eric foner"
    #  AFTER:  params[s.fq]={"AuthorCombined"=>"eric foner"}
    # [This logic is here instead of fix_summon_params, because it needs to act
    #  upon the true params object, not the cloned copy.]
    if params['s.fq'].kind_of?(Array) || params['s.fq'].kind_of?(String)
      new_fq = {}
      key_value_array = []
      Array.wrap(params['s.fq']).each do |key_value|
        key_value_array  = key_value.split(':')
        new_fq[ key_value_array[0]] = key_value_array[1] if key_value_array.size == 2
      end
      params['s.fq'] = new_fq
    end

    session['search'] = params

    # @search_layout = SEARCHES_CONFIG['search_layouts'][params['layout']]
    @search_layout = get_search_layout( params['layout'] )

    # First, try to detect if we should go to the landing page.
    # But... Facet-Only searches are still searches.
    # (Compare logic from SearchHelper#has_search_parameters?)
    if params['q'].nil? && params['s.q'].nil? &&
       params['s.fq'].nil? && params['s.ff'].nil? ||
      (params['q'].to_s.empty? && $active_source == 'library_web')
      flash[:error] = 'You cannot search with an empty string.' if params['commit']
    elsif @search_layout.nil?
      flash[:error] = 'No search layout specified'
      redirect_to root_path
    else
      @search_style = @search_layout['style']
      sources =  @search_layout['columns'].map do |col|
        col['searches'].map do |search|
          search['source']
        end
      end.flatten

      # @action_has_async = true if @search_style == 'aggregate'

      # if @search_style == 'aggregate' && !session[:async_off]
      #   @action_has_async = true
      if @search_style == 'aggregate'
        @results = {}
        sources.each { |source| @results[source] = {} }
      else
        @results = get_results(sources)
      end

    end

    @show_landing_pages = true if @results.empty?
  end


  def searchjson
    # @search_layout = SEARCHES_CONFIG['search_layouts'][params[:layout]]
    @search_layout = get_search_layout( params['layout'] )

    @datasource = params[:datasource]

    if @search_layout.nil?
      render text: 'Search layout invalid.'
    else
      # Need this to help partials select which template to render
      @search_style = @search_layout['style']

#       # @has_facets = @search_layout['has_facets']
#       sources =  @search_layout['columns'].map do |col|
#         col['searches'].map { |item| item['source'] }
#       end.flatten.select { |source| source == @datasource }
# puts "XXXXXXXXXXXXXXX searchjson() sources=#{sources.inspect}"

      @results = get_results(@datasource)

      render 'searchjson', layout: 'js_return'
   end
  end


  # Simplified version of 'searchjson' - just run a query against
  # a datasource to get a hit count.
  def hits
    datasource = params[:datasource]

    # we don't need any rows of results.  
    # params['rows'] = 1
    # ...but resetting this value can overwrite user default rows

    results = case datasource
      when 'catalog', 'academic_commons', 'geo', 'dlc'
        blacklight_search(params)
      when 'articles'
        fixed_params = fix_summon_params(params)
        fixed_params['new_search'] = 'true'
        Spectrum::SearchEngines::Summon.new(fixed_params, get_summon_facets)
      when 'library_web'
        Spectrum::SearchEngines::GoogleAppliance.new(fix_ga_params(params))
      else
        render nothing: true and return
      end

    @hits = results.total_items || 0
    render 'hits', layout: 'js_return'
  end


  def facet
    # render values of a facet, nothing else.

    # This is only used for Summon article facets
    @results = get_results(['articles'])

    respond_to do |format|
      # regular full-page view
      format.html
      # for the "more" facet modal window:
      format.js { render :layout => false }
    end

  end

  def checked_out_items
    authenticate_user! 
    @checked_out_items = BackendController.getCheckedOutBibs(current_user) || []
  end
  
  

  private

  def fix_ga_params(params)
    # items-per-page ("rows" param) should be a persisent browser setting
    if params['rows'] && (params['rows'].to_i > 1)
      # Store it, if passed
      set_browser_option('ga_per_page', params['rows'])
    else
      # Retrieve and use previous value, if not passed
      ga_per_page = get_browser_option('ga_per_page')
      if ga_per_page && (ga_per_page.to_i > 1)
        params['rows'] = ga_per_page
      end
    end

    params
  end

  def fix_summon_params(params)
    # Rails.logger.debug "fix_summon_params() in params=#{params.inspect}"

    # The Summon API support authenticated or un-authenticated roles,
    # with Authenticated having access to more searchable metadata.
    # We're Authenticated if the user is on-campus, or has logged-in.
    params['s.role'] = "authenticated" if @user_characteristics[:on_campus] || !current_user.nil?

    # items-per-page (summon page size, s.ps, aka 'rows') should be
    # a persisent browser setting
    if params['s.ps'] && (params['s.ps'].to_i > 1)
      # Store it, if passed
      set_browser_option('summon_per_page', params['s.ps'])
    else
      # Retrieve and use previous value, if not passed
      summon_per_page = get_browser_option('summon_per_page')
      if summon_per_page && (summon_per_page.to_i > 1)
        params['s.ps'] = summon_per_page
      end
    end

    # moved elsewhere
    # # Article searches within QuickSearch should act as New searches
    # params['new_search'] = 'true' if $active_source == 'quicksearch'

    # If we're coming from the LWeb Search Widget - or any other external
    # source - mark it as a New Search for the Summon search engine.
    # (fixes NEXT-948 Article searches from LWeb do not exclude newspapers)
    clios = ['http://clio', 'https://clio',
             'http://localhost', 'https://localhost']
    params['new_search'] = true unless request.referrer && clios.any? do |prefix|
      request.referrer.starts_with? prefix
    end


    # New approach, 5/14 - params will always be "q".  
    # "s.q" is internal only to the Summon controller logic
    if params['s.q']
      # s.q ovewrites q, unless 'q' is given independently
      params['q'] = params['s.q'] unless params['q']
      params.delete('s.q')
    end
    # 
    #   # LibraryWeb QuickSearch will pass us "search_field=all_fields",
    #   # which means to do a Summon search against 's.q'
    if params['q'] && params['search_field'] && (params['search_field'] != 'all_fields')
      escaped_params = URI.escape("#{params['search_field']}=#{params['q']}" )
      hash = Rack::Utils.parse_nested_query(escaped_params)
      params.merge! hash
      # params.delete('q') unless params['search_field'] == 'q'
    end

    if params['pub_date']
      params['s.cmd'] = "setRangeFilter(PublicationDate,#{params['pub_date']['min_value']}:#{params['pub_date']['max_value']})"
    end

    # Rails.logger.debug "fix_summon_params() out params=#{params.inspect}"
    params
  end

  def get_results(sources)
    @result_hash = {}
    new_params = params.to_hash
    sources.listify.each do |source|

      fixed_params = new_params.deep_clone
      %w(layout commit source sources controller action).each do |param_name|
        fixed_params.delete(param_name)
      end

      fixed_params['source'] = source

      # "results" is not the search results, it's the Search Engine object, in a
      # post-search-execution state.
      # TODO: drive this case statement off yml config files
      results = case source
        when 'articles', 'summon_dissertations', 'summon_ebooks'
          fixed_params = fix_summon_params(fixed_params)
          fixed_params['new_search'] = true if params['layout'] == 'quicksearch'
          Spectrum::SearchEngines::Summon.new(fixed_params, get_summon_facets)

        when 'catalog', 'databases', 'journals', 'catalog_ebooks', 'catalog_dissertations', 'academic_commons', 'ac_dissertations', 'geo', 'dlc'
          blacklight_search(fixed_params)

        when 'library_web'
          # GoogleAppliance search engine can't handle absent q param
          fixed_params['q'] ||= ''
          fixed_params = fix_ga_params(fixed_params)
          Spectrum::SearchEngines::GoogleAppliance.new(fixed_params)

        else
          fail "SpectrumController#get_results() unhandled source: '#{source}'"
        end

      @result_hash[source] = results
    end

    @result_hash
  end


end

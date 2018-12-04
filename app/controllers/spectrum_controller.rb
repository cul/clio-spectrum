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
class SpectrumController < ApplicationController
  layout 'quicksearch'

  def search
    # don't support alternative formats for non-catalog datasources
    return render body: nil, status: :not_found if params['format']

    @results = []

    # process any Filter Queries - turn Summon API Array of key:value pairs into
    # nested Rails hash (see inverse transform in Spectrum::SearchEngines::Summon)
    #  BEFORE: params[s.fq]="AuthorCombined:eric foner"
    #  AFTER:  params[s.fq]={"AuthorCombined"=>"eric foner"}
    # [This logic is here instead of fix_summon_params, because it needs to act
    #  upon the true params object, not the cloned copy.]
    if params['s.fq'].is_a?(Array) || params['s.fq'].is_a?(String)
      new_fq = {}
      key_value_array = []
      Array.wrap(params['s.fq']).each do |key_value|
        key_value_array = key_value.split(':')
        new_fq[key_value_array[0]] = key_value_array[1] if key_value_array.size == 2
      end
      params['s.fq'] = new_fq
    end

    session['search'] = params

    @search_layout = get_search_layout(params['layout'])

    # First, try to detect if we should go to the landing page.
    # But... Facet-Only searches are still searches.
    # (Compare logic from SearchHelper#has_search_parameters?)
    if params['q'].nil? && params['s.q'].nil? &&
       params['s.fq'].nil? && params['s.ff'].nil? ||
       (params['q'].to_s.empty? && active_source == 'library_web')
      flash[:error] = 'You cannot search with an empty string.' if params['commit']
    elsif @search_layout.nil?
      flash[:error] = 'No search layout specified'
      redirect_to root_path
    else
      @search_style = @search_layout['style']
      sources = @search_layout['columns'].map do |col|
        col['searches'].map do |search|
          search['source']
        end
      end.flatten

      if @search_style == 'aggregate'
        @results = {}
        sources.each { |source| @results[source] = {} }
      else
        # Non-aggregate non-blacklight search (e.g., Summon)
        @results = get_results(sources.first)
      end

    end

    @show_landing_pages = true if @results.empty?
  end

  def searchjson
    # puts "MMMM  searchjson() Thread #{Thread.current.object_id} params[:datasource]=#{params[:datasource]}  self=#{self}"
    # puts "AAA#{Thread.current.object_id} --- #{active_source} searchjson params=#{params}"
    @search_layout = get_search_layout(params['layout'])

    return render plain: 'Search layout invalid.' if @search_layout.nil?

    # Need this to help partials select which template to render
    @search_style = @search_layout['style']

    # @datasource = params[:datasource]
    @results = get_results(params[:datasource])

    # puts "MM MM MM searchjson() GOT RESULTS - Thread #{Thread.current.object_id} params[:datasource]=#{params[:datasource]}  self=#{self}"

    # puts "ZZZ#{Thread.current.object_id} --- active_source=#{active_source} @datasource=#{@datasource} active_source=#{active_source}"
    render 'searchjson', layout: 'js_return'
  end

  # Simplified version of 'searchjson' - just run a query against
  # a datasource to get a hit count.
  def hits
    hit_params = params.to_unsafe_h
    hit_params[:source] = hit_params[:datasource]
    # datasource = params[:datasource]

    # we don't need any rows of results.
    # params['rows'] = 1
    # ...but resetting this value can overwrite user default rows

    results = case hit_params[:datasource]
              when 'catalog', 'academic_commons', 'geo', 'dlc'
                blacklight_search(hit_params)
              when 'articles'
                fixed_params = fix_summon_params(hit_params)
                fixed_params['new_search'] = 'true'
                Spectrum::SearchEngines::Summon.new(fixed_params, get_summon_facets)
              when 'library_web'
                Spectrum::SearchEngines::GoogleAppliance.new(fix_ga_params(hit_params))
              when 'lweb'
                Spectrum::SearchEngines::GoogleCustomSearch.new(hit_params)
              when 'ac'
                Spectrum::SearchEngines::Ac.new(hit_params)
              else
                render(body: nil) && return
      end

    @hits = results.total_items || 0
    render 'hits', layout: 'js_return'
  end

  def facet
    # render values of a facet, nothing else.

    # This is only used for Summon article facets
    @results = get_results('articles')

    respond_to do |format|
      # regular full-page view
      format.html
      # for the "more" facet modal window:
      format.js { render layout: false }
    end
  end

  def checked_out_items
    authenticate_user!
    patron = current_user.login
    @label = 'You have'

    # Admins can snoop other people's checked-out items
    if current_user.admin? && params[:uni]
      patron = params[:uni]
      @label = "#{patron} has"
    end

    # @checked_out_items = BackendController.getCheckedOutItems(patron) || []
    @checked_out_items = checked_out_bibs(patron)
  end

  private

  def checked_out_bibs(patron = '')
    return [] unless patron.present?

    items = BackendController.getCheckedOutItems(patron) || []

    # Map Items to Bibs
    bibs = []
    bibs_seen = []
    items.each do |item|
      bib_id = item[:bib_id]
      next if bibs_seen.include?(bib_id)

      # For ReCAP Partner items, lookup bib details in Solr by barcode
      if item[:title].present? && item[:title].include?('[RECAP]')
        barcode = item[:barcode]
        params = { q: "barcode_txt:#{barcode}", facet: 'off', source: 'catalog' }
        result = blacklight_search(params)
        documents = result.documents || nil
        if documents.present? && !documents.empty?
          document = documents.first
          item[:bib_id]     = document.id
          item[:author]     = doc_field(document, :author_display)
          item[:title]      = doc_field(document, :title_display)
          item[:pub_name]   = doc_field(document, :pub_name_display)
          item[:pub_date]   = doc_field(document, :pub_year_display)
          item[:pub_place]  = doc_field(document, :pub_place_display)
        end
      end

      bibs << item
      bibs_seen << bib_id
    end

    bibs
  end

  def doc_field(doc = nil, field = nil)
    return '' if doc.blank? || field.blank?
    doc = doc.first if doc.is_a? Array
    value = doc[field] || ''
    value = value.join(', ') if value.is_a? Array
    value
  end

  def fix_ga_params(params)
    # items-per-page ("rows" param) should be a persisent browser setting
    if params['rows'] && (params['rows'].to_i > 1)
      # Store it, if passed
      set_browser_option('ga_per_page', params['rows'])
    else
      # Retrieve and use previous value, if not passed
      ga_per_page = get_browser_option('ga_per_page')
      params['rows'] = ga_per_page if ga_per_page && (ga_per_page.to_i > 1)
    end

    params
  end

  def fix_summon_params(params)
    # Rails.logger.debug "fix_summon_params() in params=#{params.inspect}"

    # The Summon API support authenticated or un-authenticated roles,
    # with Authenticated having access to more searchable metadata.
    # We're Authenticated if the user is on-campus, or has logged-in.
    params['s.role'] = 'authenticated' if @user_characteristics[:on_campus] || !current_user.nil?

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
      escaped_params = URI.escape("#{params['search_field']}=#{params['q']}")
      hash = Rack::Utils.parse_nested_query(escaped_params)
      params.merge! hash
      # params.delete('q') unless params['search_field'] == 'q'
    end

    if params['pub_date']
      min, max = parse_pub_date(params['pub_date'])
      if min.present? || max.present?
        params['s.cmd'] = "setRangeFilter(PublicationDate,#{min}:#{max})"
      end
    end

    # Rails.logger.debug "fix_summon_params() out params=#{params.inspect}"
    params
  end

  def parse_pub_date(pub_date)
    min = parse_single_date(pub_date['min_value'])
    max = parse_single_date(pub_date['max_value'])
    [min, max]
  end

  def parse_single_date(date)
    return '' if date.blank?
    return '' unless date =~ /^[\d\/]+$/
    # "2001"
    return date if date =~ /^\d+$/
    parts = date.split('/')
    # 12/1999 --> 1999-12
    if parts.size == 2
      month = sprintf '%02d', parts[0].to_i
      year = parts[1].length == 2 ? '20' + parts[1] : parts[1]
      return [year, month].join('-')
    end
    # 12/20/1999 --> 1999-12-20
    if parts.size == 3
      month = sprintf '%02d', parts[0].to_i
      day = sprintf '%02d', parts[1].to_i
      year = parts[2].length == 2 ? '20' + parts[2] : parts[2]
      return [year, month, day].join('-')
    end
  end

  def get_results(source)
    @result_hash = {}
    new_params = params.to_unsafe_h

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
                # puts "BBB#{Thread.current.object_id}  source #{source} - summon 'when' branch"
                fixed_params = fix_summon_params(fixed_params)
                fixed_params['new_search'] = true if params['layout'] == 'quicksearch'
                Spectrum::SearchEngines::Summon.new(fixed_params, get_summon_facets)

              when 'catalog', 'databases', 'journals', 'catalog_ebooks', 'catalog_dissertations', 'catalog_data', 'XXacademic_commons', 'XXac_dissertations', 'XXac_data', 'geo', 'geo_cul', 'dlc'
                # puts "BBB#{Thread.current.object_id}  source #{source} - blacklight_search 'when' branch"
                blacklight_search(fixed_params)

              when 'library_web'
                # puts "BBB#{Thread.current.object_id}  source #{source} - library_web 'when' branch"
                # GoogleAppliance search engine can't handle absent q param
                fixed_params['q'] ||= ''
                fixed_params = fix_ga_params(fixed_params)
                Spectrum::SearchEngines::GoogleAppliance.new(fixed_params)

              when 'lweb'
                Spectrum::SearchEngines::GoogleCustomSearch.new(fixed_params)

              when 'ac', 'ac_dissertations', 'ac_data', 'academic_commons'
                # temporary support for 8/18 cutover to AC4
                source = 'ac' if source == 'academic_commons'
                Spectrum::SearchEngines::Ac.new(fixed_params)

              else
                # bad input?  log and return nil results
                Rails.logger.error "SpectrumController#get_results() unhandled source: '#{source}'"
                return @result_hash
      end

    @result_hash[source] = results

    @result_hash
  end
end

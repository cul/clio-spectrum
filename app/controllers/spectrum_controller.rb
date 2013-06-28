class SpectrumController < ApplicationController
  include Blacklight::Controller
  include Blacklight::Catalog
  include Blacklight::Configurable
  include BlacklightRangeLimit::ControllerOverride
  layout 'quicksearch'

  def search
    @results = []
    session['search'] = params

    @search_layout = SEARCHES_CONFIG['layouts'][params['layout']]

      if params['q'].nil? && params['s.q'].nil? || (params['q'].to_s.empty? && @active_source == 'library_web')
        flash[:error] = "You cannot search with an empty string." if params['commit']
      elsif @search_layout.nil?
        flash[:error] = "No search layout specified"
        redirect_to root_path
      else
        @search_style = @search_layout['style']
        @has_facets = @search_layout['has_facets']
        categories =  @search_layout['columns'].collect { |col| col['searches'].collect { |item| item['source'] }}.flatten

        @action_has_async = true if @search_style == 'aggregate'

        if @search_style == 'aggregate' && !session[:async_off]
          @action_has_async = true
          @results = {}
          categories.each { |source| @results[source] = {} }
        else

          @results = get_results(categories)
        end

      end

    @show_landing_pages = true if @results.empty?
  end


  def fetch

    @search_layout = SEARCHES_CONFIG['layouts'][params[:layout]]

    @datasource = params[:datasource]

    if @search_layout.nil?
      render :text => "Search layout invalid."
    else
      @fetch_action = true
      @search_style = @search_layout['style']
      @has_facets = @search_layout['has_facets']
      categories =  @search_layout['columns'].collect { |col| col['searches'].collect { |item| item['source'] }}.flatten.select { |source| source == @datasource }

      @results = get_results(categories)
      render 'fetch', layout: 'js_return'

    end

  end

  def catch_404
    unrouted_uri = request.fullpath
    alert = "Invalid URL: #{unrouted_uri}"
    logger.warn alert
    redirect_to root_path, :alert => alert
  end

  private

  def fix_articles_params(param_list)
    param_list['authorized'] = @user_characteristics[:authorized]
    if param_list['q']
      param_list['s.q'] ||= param_list['q']
      session['search']['s.q'] = param_list['q']
      param_list['new_search'] = true
      param_list.delete('q')

    end

    if param_list['pub_date']
      param_list['s.cmd'] = "setRangeFilter(PublicationDate,#{param_list['pub_date']['min_value']}:#{param_list['pub_date']['max_value']})"
      param_list.delete('q')

    end

    param_list

  end

  def get_results(categories)
    @result_hash = {}
    new_params = params.to_hash
    categories.listify.each do |category|

      fixed_params = new_params.deep_clone
      %w{layout commit source categories controller action}.each { |param_name| fixed_params.delete(param_name) }
      fixed_params.delete(:source)

      results = case category

        when 'articles_dissertations'
          fixed_params['source'] = 'dissertations'
          fixed_params = fix_articles_params(fixed_params)
          Spectrum::Engines::Summon.new(fixed_params)

        when 'articles'
          fixed_params['source'] = 'articles'
          fixed_params = fix_articles_params(fixed_params)
          Spectrum::Engines::Summon.new(fixed_params)

        when 'articles_newspapers'
          fixed_params['source'] = 'newspapers'
          fixed_params = fix_articles_params(fixed_params)
          Spectrum::Engines::Summon.new(fixed_params)

        when 'ebooks'
          fixed_params['source'] = 'ebooks'
          fixed_params = fix_articles_params(fixed_params)
          Spectrum::Engines::Summon.new(fixed_params)

        when 'catalog_ebooks'
          fixed_params['source'] = 'catalog_ebooks'
          blacklight_search(fixed_params)

        when 'catalog_databases'
          fixed_params['source'] = 'databases'
          blacklight_search(fixed_params)

        when 'catalog_ejournals'
          fixed_params['source'] = 'journals'
          blacklight_search(fixed_params)

        when 'catalog_dissertations'
          fixed_params['source'] = 'catalog_dissertations'
          blacklight_search(fixed_params)

        when 'catalog'
          fixed_params['source'] = 'catalog'
          blacklight_search(fixed_params)

        when 'academic_commons'
          fixed_params['source'] = 'academic_commons'
          blacklight_search(fixed_params)

        when 'ac_dissertations'
          fixed_params['source'] = 'ac_dissertations'
          blacklight_search(fixed_params)

        when 'library_web'
          # GoogleAppliance engine can't handle absent q param
          fixed_params['q'] ||= ''
          Spectrum::Engines::GoogleAppliance.new(fixed_params)
        end

      @result_hash[category] = results
    end

    @result_hash
  end
end

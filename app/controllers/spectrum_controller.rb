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

      if params['q'].to_s.strip.empty? && params['s.q'].to_s.strip.empty?
        flash[:error] = "You cannot search with an empty string." if params['commit']
      elsif @search_layout.nil?
        flash[:error] = "No search layout specified"
        redirect_to root_path
      else
        @search_style = @search_layout['style']
        categories =  @search_layout['columns'].collect { |col| col['searches'].collect { |item| item['source'] }}.flatten

        @results = get_results(categories)

      end
  end
  private

  def fix_articles_params(param_list)
    if param_list['q']
      param_list['s.q'] ||= param_list['q']
      session['search']['s.q'] = param_list['q'] 
      param_list['new_search'] = true
      param_list.delete('q')

    end

    param_list
    
  end

  def get_results(categories)
    @result_hash = {}
    new_params = params.to_hash
    categories.listify.each do |category|
<<<<<<< HEAD
      begin
        results = case category
                  when 'articles_dissertations'
                    summon = SerialSolutions::SummonAPI.new('category' => 'dissertations', 'new_search' => true,  's.q' => params[:q])

                    {
                      :result => summon.search,
                      :docs => summon.search.respond_to?(:documents) ? summon.search.documents : [],
                      :count => summon.search.record_count.to_i, 
                      :url => articles_search_path(summon.search.query.to_hash)
                    }
                  when 'articles'
                    summon = SerialSolutions::SummonAPI.new('category' => 'articles', 'new_search' => true, 's.q' => params[:q], 's.ps' => 10)

                    {
                      :result => summon.search,
                      :docs => summon.search.respond_to?(:documents) ? summon.search.documents : [],
                      :count => summon.search.record_count.to_i, 
                      :url => articles_search_path(summon.search.query.to_hash)
                    }
                  when 'articles_newspapers'
                    summon = SerialSolutions::SummonAPI.new('category' => 'newspapers', 'new_search' => true, 's.q' => params[:q], 's.ps' => 10)

                    {
                      :result => summon.search,
                      :docs => summon.search.respond_to?(:documents) ? summon.search.documents : [],
                      :count => summon.search.record_count.to_i, 
                      :url => articles_search_path(summon.search.query.to_hash)
                    }
                  when 'ebooks'
                    summon = SerialSolutions::SummonAPI.new('category' => 'ebooks', 'new_search' => true, 's.q' => params[:q], 's.ps' => 10)
                    {
                      :result => summon.search,
                      :docs => summon.search.respond_to?(:documents) ? summon.search.documents : [],
                      :count => summon.search.record_count.to_i,
                      :url => articles_search_path(summon.search.query.to_hash)
                    }
                  when 'catalog_ebooks'
                    params[:rows] = 15
                    params[:f] = {'format' => ['Book', 'Online']}
                  
                    solr_response, solr_results = blacklight_search(params.merge(:source => 'catalog'))
                    look_up_clio_holdings(solr_results)
                    {
                      :result => solr_response,
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => url_for(:controller => 'catalog', :action => 'index', :q => params['q'], :f => {'format' => ['Book', 'Online']})
                    }
                  when 'catalog_databases'

                    params[:rows] = 15
                    params[:f] = {'source_facet' => ['database']}
                    solr_response, solr_results = blacklight_search(params.merge(:source => 'catalog'))
                    look_up_clio_holdings(solr_results)
                    {
                      :result => solr_response,
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => url_for(:controller => 'catalog', :action => 'index', :q => params['q'], :f => {'source_facet' => ['database']})
                    }
                  when 'catalog_ejournals'

                    params[:rows] = 15
                    params[:f] = {'source_facet' => ['ejournal']}
                    solr_response, solr_results = blacklight_search(params.merge(:source => 'catalog'))
                    look_up_clio_holdings(solr_results)
                    {
                      :result => solr_response,
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => url_for(:controller => 'catalog', :action => 'index', :q => params['q'], :f => {'source_facet' => ['ejournal']})
                    }
                  when 'catalog_dissertations'

                    params[:rows] = 15
                    params[:f] = {'format' => ['Thesis']}
                    solr_response, solr_results = blacklight_search(params.merge(:source => 'catalog'))
                    look_up_clio_holdings(solr_results)
                    {
                      :result => solr_response,
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => url_for(:controller => 'catalog', :action => 'index', :q => params['q'], :f => {'format' => ['Thesis']})
                    }
                  when 'catalog'
                    params[:rows] = 15
                    solr_response, solr_results = blacklight_search(params.merge(:source => 'catalog'))
                    look_up_clio_holdings(solr_results)
                    {
                      :result => solr_response,
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => url_for(:controller => 'catalog', :action => 'index', :q => params['q'])
                    }
                  when 'academic_commons'
                    params[:rows] = 15

                    solr_response, solr_results = blacklight_search(params.merge(:source => 'academic_commons'))
                    {
                      :result => solr_response,
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => academic_commons_index_path(:q => params['q'])
                    }
                  when 'ac_dissertations'
                    params[:rows] = 3
                    params[:genre_facet] = ['Dissertations']
                    params[:f] = {'genre_facet' => ['Dissertations']}
                    solr_response, solr_results = blacklight_search(params.merge(:source => 'academic_commons'))
                    {
                      :result => solr_response,
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => academic_commons_index_path(:q => params['q'], :f => {'genre_facet' => ['Dissertations']})
                      
                    }
                  when 'library_web'
                    @search = LibraryWeb::Api.new('q' => params['q'], 'start' => params['start'].to_i)
                    {
                      :result => solr_response,
                      :docs => @search.docs,
                      :count => @search.count, 
                      :url => library_web_index_path(:q => params['q'])
                    }

                  end
      rescue Exception => e
        results = { :error => true, :message => e.message, :docs => [] }
    
      end
=======
      
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
          Spectrum::Engines::GoogleAppliance.new(fixed_params)
        end
>>>>>>> b019750d3274b23112c560838905783c8b3222aa

      @result_hash[category] = results
    end

    @result_hash
  end
end

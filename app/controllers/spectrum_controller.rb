class SpectrumController < ApplicationController
  include Blacklight::Controller
  include Blacklight::Catalog
  include Blacklight::Configurable
  include BlacklightRangeLimit::ControllerOverride
  layout 'quicksearch'

  def search
    @results = []
    session['search'] = params
    session['search']['s.q'] = params['q'] if params['q']

    @search_layout = SEARCHES_CONFIG['layouts'][params['layout']]

    if params['q'].to_s.strip.empty? 
      flash[:error] = "You cannot search with an empty string." if params['commit']
    elsif @search_layout.nil?
      flash[:error] = "Invalid layout selected."
    else
      @search_style = @search_layout['style']
      params['categories'] = @search_layout['columns'].collect { |col| col['searches'].collect { |item| item['source'] }}.flatten

      @results = get_results(params['categories'])
    end
  end
  private

  def get_results(categories)
    @result_hash = {}
    categories.listify.each do |category|
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
                    params[:per_page] = 15
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

                    params[:per_page] = 15
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

                    params[:per_page] = 15
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

                    params[:per_page] = 15
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
                    params[:per_page] = 15
                    solr_response, solr_results = blacklight_search(params.merge(:source => 'catalog'))
                    look_up_clio_holdings(solr_results)
                    {
                      :result => solr_response,
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => url_for(:controller => 'catalog', :action => 'index', :q => params['q'])
                    }
                  when 'academic_commons'
                    params[:per_page] = 15

                    solr_response, solr_results = blacklight_search(params.merge(:source => 'academic_commons'))
                    {
                      :result => solr_response,
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => academic_commons_index_path(:q => params['q'])
                    }
                  when 'ac_dissertations'
                    params[:per_page] = 3
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

      results.merge(:category => category)
      @result_hash[category] = results
    end

    @result_hash
  end
end

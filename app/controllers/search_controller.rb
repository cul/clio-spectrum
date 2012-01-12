class SearchController < ApplicationController
  include Blacklight::Catalog
  layout 'quicksearch'

  CATEGORY_ORDER = %w{catalog articles ebooks lweb catalog_ebooks}

  def index
    @results = []
    params['categories'] = ['catalog', 'articles', 'lweb']

    raise('test') if params['throw_error']

    if params['q'].to_s.strip.empty? 
      flash[:error] = "You cannot search with an empty string." if params['commit']
    else
      active_categories = CATEGORY_ORDER.select { |cat| params['categories'].listify.include?(cat) }



      case active_categories.length 
      when 0
        flash[:error] = "You must select a category to search."
      when 1
        redirect_to search_url_for(active_categories.first, params)
      else
        @results= get_results(active_categories)
       

      end


    end

  end

  def ebooks
    params['categories'] = ['catalog_ebooks', 'ebooks']

    @results = {}
    if params['q'].to_s.strip.empty? 
      flash[:error] = "You cannot search with an empty string." if params['commit']
    else
      @results = get_results(params['categories'])

    end
  end

  private

  def get_results(categories)
    @result_hash = {}
    categories.listify.each do |category|
      begin
        results = case category
                  when 'articles'
                    summon = SerialSolutions::SummonAPI.new('category' => 'articles', 'new_search' => true, 's.q' => params[:q], 's.ps' => 10)

                    {
                      :docs => summon.search,
                      :count => summon.search.record_count.to_i, 
                      :url => article_search_path(summon.search.query.to_hash)
                    }
                  when 'ebooks'
                    summon = SerialSolutions::SummonAPI.new('category' => 'ebooks', 'new_search' => true, 's.q' => params[:q], 's.ps' => 10)
                    {
                      :docs => summon.search,
                      :count => summon.search.record_count.to_i,
                      :url => article_search_path(summon.search.query.to_hash)
                    }
                  when 'catalog_ebooks'
                    params[:per_page] = 15
                    params[:f] = {'format' => ['Book', 'Online']}
                    solr_response, solr_results =  get_search_results
                    {
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => url_for(:controller => 'catalog', :action => 'index', :q => params['q'], :f => {'format' => ['Book', 'Online']})
                    }
                  when 'catalog'
                    params[:per_page] = 15
                    solr_response, solr_results =  get_search_results
                    {
                      :docs => solr_results,
                      :count => solr_response['response']['numFound'].to_i,
                      :url => url_for(:controller => 'catalog', :action => 'index', :q => params['q'])
                    }
                  when 'lweb'
                    search_result = Nokogiri::XML(HTTPClient.new.get_content('http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&output=xml&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=10&x=0&y=0&q=' +  CGI::escape(params[:q])))

                    docs = search_result.css("R").collect do |xml_node|
                      content_or_nil = lambda { |node| node ? node.content : nil }
                      { 
                        :url => content_or_nil.call(xml_node.at_css('UE')),
                        :title => content_or_nil.call(xml_node.at_css('T')),
                        :summary => content_or_nil.call(xml_node.at_css('S'))
                      }
                    end

                    {
                      :docs => docs,
                      :count => (search_result.at_css("M") ? search_result.at_css("M").content.to_i : 0),

                      :url =>  'http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&proxystylesheet=cul_libraryweb&output=xml_no_dtd&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=20&x=0&y=0&q=' +  CGI::escape(params[:q])
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


  def search_url_for(category, params)
    case category
    when 'articles'
      article_search_path('s.q' => params['q'], :new_search => 'articles')
    when 'ebooks'
      article_search_path('s.q' => params['q'], :new_search => 'ebooks')
    when 'catalog'
      url_for(:controller => 'catalog', :action => 'index', :q => params['q'])
    when 'catalog_ebooks'
      url_for(:controller => 'catalog', :action => 'index', :q => params['q'], :f => {'format' => ['Book', 'Online']})
    when 'lweb'
      'http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&proxystylesheet=cul_libraryweb&output=xml_no_dtd&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=20&x=0&y=0&q=' +  CGI::escape(params[:q])
    when 'lweb_xml'
      'http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&output=xml&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=10&x=0&y=0&q=' +  CGI::escape(params[:q])
    end
  end

end

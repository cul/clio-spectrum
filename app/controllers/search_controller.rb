class SearchController < ApplicationController
  include Blacklight::Catalog
  layout "aggregate"

  CATEGORY_ORDER = %w{catalog articles ebooks lweb}

  def index
    @results = []

    if params['commit']
      if params[:q].to_s.strip.empty?
        flash[:error] = "You cannot search with an empty string."
      else
        active_categories = CATEGORY_ORDER.select { |cat| params['categories'].listify.include?(cat) }



        case active_categories.length 
        when 0
          flash[:error] = "You must select a category to search."
        when 1
          redirect_to search_url_for(active_categories.first, params)
        else
          @results= active_categories.collect do |category|
            get_results_for_category(category)
          end

        end


      end
    end
    
    params['categories'] ||= ['catalog', 'articles','ebooks'] unless params.has_key?('q')
    params['categories'] ||= []
  end
  private

  def get_results_for_category(category)
    results = case category
    when 'articles'
      search = SerialSolutions::SummonAPI.search('s.q' => params[:q], 's.ps' => 10)
      
      {
        :docs => search,
        :count => search.record_count, 
        :url => article_search_path('s.q' => params['q'], :category => 'articles')
      }
    when 'ebooks'
      search = SerialSolutions::SummonAPI.search('s.q' => params[:q], 's.ps' => 10, 's.fvf' => "ContentType,eBook")
      {
        :docs => search,
        :count => search.record_count,
        :url => article_search_path('s.q' => params['q'], :category => 'ebooks')
      }
    when 'catalog'
      params[:per_page] = 10
      solr_response, solr_results =  get_search_results
      {
        :docs => solr_results,
        :count => solr_response[:total],
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
        :count => search_result.css("M"),
        :url =>  'http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&proxystylesheet=cul_libraryweb&output=xml_no_dtd&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=20&x=0&y=0&q=' +  CGI::escape(params[:q])
      }

    end
    results.merge(:category => category)

  end


  def search_url_for(category, params)
    case category
    when 'articles'
      article_search_path('s.q' => params['q'], :new_search => 'articles')
    when 'ebooks'
      article_search_path('s.q' => params['q'], :new_search => 'ebooks')
    when 'catalog'
      url_for(:controller => 'catalog', :action => 'index', :q => params['q'])
    when 'lweb'
      'http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&proxystylesheet=cul_libraryweb&output=xml_no_dtd&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=20&x=0&y=0&q=' +  CGI::escape(params[:q])
    when 'lweb_xml'
      'http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&output=xml&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=10&x=0&y=0&q=' +  CGI::escape(params[:q])
    end
  end

end

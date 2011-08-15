class SearchController < ApplicationController
  include Blacklight::Catalog
  layout 'aggregate'

  CATEGORY_ORDER = %w{catalog articles lweb}

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
            {
              :category => category,
              :url => search_url_for(category, params),
              :docs => search_results_for(category, params)
            }
          end

        end


      end
    end
    
    params['categories'] ||= ['catalog', 'articles','lweb'] unless params.has_key?('q')
    params['categories'] ||= []
  end
  private

  def search_results_for(category, params)
    case category
    when 'articles'
      summon = Summon::Service.new(APP_CONFIG[:summon])
      summon.search('s.q' => params[:q], 's.ps' => 10)
    when 'catalog'
      params[:per_page] = 10
      solr_response, solr_results =  get_search_results
      solr_results
    when 'lweb'
      search_result = Nokogiri::XML(HTTPClient.new.get_content(search_url_for('lweb_xml', params)))

      search_result.css("R").collect do |xml_node|
        content_or_nil = lambda { |node| node ? node.content : nil }
        { 
          :url => content_or_nil.call(xml_node.at_css('UE')),
          :title => content_or_nil.call(xml_node.at_css('T')),
          :summary => content_or_nil.call(xml_node.at_css('S'))
        }
      end
    end
  end

  def search_url_for(category, params)
    case category
    when 'articles'
      'http://columbia.summon.serialssolutions.com/search?s.cmd=addFacetValueFilters%28ContentType%2CNewspaper+Article%3At%29&spellcheck=true&x=0&y=0&s.q=' + CGI::escape(params[:q])
    when 'catalog'
      url_for(:controller => 'catalog', :action => 'index', :q => params['q'])
    when 'lweb'
      'http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&proxystylesheet=cul_libraryweb&output=xml_no_dtd&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=20&x=0&y=0&q=' +  CGI::escape(params[:q])
    when 'lweb_xml'
      'http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&output=xml&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=10&x=0&y=0&q=' +  CGI::escape(params[:q])
    end
  end

end

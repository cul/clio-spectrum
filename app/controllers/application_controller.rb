class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller
  include Blacklight::Catalog
  include Blacklight::Configurable
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 
  check_authorization
  skip_authorization_check

  before_filter :trigger_debug_mode
  before_filter :by_source_config
  before_filter :log_additional_data

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def look_up_clio_holdings(documents)
    clio_docs = documents.select { |d| d.get('clio_id_display')}
    
    begin
      unless clio_docs.empty? 
        holdings = Voyager::Request.simple_holdings_check(connection_details: APP_CONFIG['voyager_connection']['oracle'], bibids: clio_docs.collect { |cd| cd.get('clio_id_display')})
        clio_docs.each do |cd|
          cd['clio_holdings'] = holdings[cd.get('clio_id_display')]
        end
      end
    rescue Exception => e
    
    end

  end

  def get_and_debug_search_results(user_params = params || {}, extra_controller_params = {})
    if @debug_mode
      results = nil
      extra_controller_params.merge!('debugQuery' => 'true')

      debug_results = lambda do |*args|       
        @debug_entries['solr'] = [] if @debug_entries['solr'] == {}
        event =   ActiveSupport::Notifications::Event.new(*args)

        hashed_event = {
          debug_uri: event.payload[:uri].to_s.gsub('wt=ruby&',"wt=xml&")+"&debugQuery=true",

        }

        @debug_entries['solr'] << hashed_event if current_user && current_user.has_role?('site', 'admin')
      end

      ActiveSupport::Notifications.subscribed(debug_results, "execute.rsolr_client") do |*args|
        results  = get_search_results(user_params, extra_controller_params)
        @debug_entries['solr'] = []  if @debug_entries['solr'] == {}
        hashed_event = {
          timing: results.first['debug']['timing'],
          parsedquery: results.first['debug']['parsedquery'].to_s,
          params: results.first['params']
        }
        
        @debug_entries['solr'] << hashed_event
      end
      
      return results
    else
      get_search_results(user_params, extra_controller_params)

    end
  end


  def trigger_debug_mode
    RSolr::Client.send(:include, RSolr::Ext::Notifications)
    RSolr::Client.enable_notifications!


    if params['debug_mode'] == 'on'

      @debug_mode = true
    elsif params['debug_mode'] == 'off'
      @debug_mode = false
    else
      @debug_mode ||= session['debug_mode'] || false
    end
    params.delete('debug_mode')
    session['debug_mode'] = @debug_mode

    unless current_user 
      session['debug_mode'] == "off"
      @debug_mode = false
    end

    @debug_entries = Hash.arbitrary_depth

    default_debug
  end

  def default_debug
    @debug_entries['params'] =params
    @debug_entries['session'] = session
  end

  
  def determine_active_source
    if params['active_source']
      @active_source = params['active_source'].underscore
    else
      path_minus_advanced = request.path.to_s.gsub(/^\/advanced/, '')
      @active_source = case path_minus_advanced 
      when /^\/databases/
        'databases'
      when /^\/new_arrivals/
        'new_arrivals'
      when /^\/catalog/
        'catalog'
      when /^\/articles/
        'articles'
      when /^\/journals/
        'journals'
      when /^\/dissertations/
        'dissertations'
      when /^\/ebooks/
        'ebooks'
      when /^\/academic_commons/
        'academic_commons'
      when /^\/library_web/
        'library_web'
      when /^\/newspapers/
        'newspapers'
      when /^\/archives/
        'archives'
      else
        params['active_source'] || 'quicksearch'
      end
    end
  end




  private
  def configure_search(source)

    if source == "academic_commons"
      Blacklight.solr = RSolr.connect(:url => APP_CONFIG['ac2_solr_url'])
    else
      Blacklight.solr = RSolr.connect(Blacklight.solr_config)
    end
    if self.respond_to?(:blacklight_config)
      if source.in?('quicksearch','ebooks','dissertations')
        self.blacklight_config = Blacklight::Configuration.new do |config|
          config.default_solr_params = {
            :qt => 'search',
            :rows => 10
          }

          config.add_search_field 'all_fields', :label => 'All Fields'
      
          config.spell_max = 0
          default_catalog_config(config)
        end
      else
        self.blacklight_config = Blacklight::Configuration.new do |config|
          config.default_solr_params = {
            :qt => 'search',
            :rows => 10
          }

          config.add_search_field 'all_fields', :label => 'All Fields'
          config.document_solr_request_handler = "document"

          case source
          when 'journals'
            default_catalog_config(config, :display_fields, :sorts)

            config.default_solr_params = {
              :qt => "search",
              :per_page => 10,
              :fq  => ['{!raw f=source_facet}ejournal']
            }

            config.add_facet_field "language_facet", :label => "Language", :limit => 5, :open => true
            config.add_facet_field "subject_topic_facet", :label => "Subject", :limit => 10
            config.add_facet_field "subject_geo_facet", :label => "Subject (Region)", :limit => 10
            config.add_facet_field "subject_era_facet", :label => "Subject (Era)", :limit => 10
            config.add_facet_field "subject_form_facet", :label => "Subject (Genre)", :limit => 10
            config.add_facet_field 'title_first_facet', :label => "Starts With"
            config[:unapi] = {
              'oai_dc_xml' => { :content_type => 'text/xml' }
            }

          when 'databases'
            default_catalog_config(config, :display_fields)


            config.default_solr_params = {
              :qt => "search",
              :per_page => 10,
              :fq  => ['{!raw f=source_facet}database']
            }

            config[:unapi] = {
              'oai_dc_xml' => { :content_type => 'text/xml' }
            }

            config.add_facet_field "database_hilcc_facet", :label => "Subject (HILCC)", :limit => 5, :open => true
            config.add_facet_field "database_resource_type_facet", :label => "Resource Type", :limit => 5
            config.add_facet_field "language_facet", :label => "Language", :limit => 5
            config.add_facet_field "subject_topic_facet", :label => "Subject", :limit => 10
            config.add_facet_field "subject_geo_facet", :label => "Subject (Region)", :limit => 10
            config.add_facet_field "subject_era_facet", :label => "Subject (Era)", :limit => 10
            config.add_facet_field "subject_form_facet", :label => "Subject (Genre)", :limit => 10
            config.add_facet_field "lc_1letter_facet", :label => "Call Number", :limit => 26, :open => false
            config.add_facet_field "lc_2letter_facet", :label => "Refine Call Number", :limit => 26
            config.add_facet_field 'title_first_facet', :label => "Starts With"
            config.add_sort_field   'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
            config[:unapi] = {
              'oai_dc_xml' => { :content_type => 'text/xml' }
            }


          when 'archives'
            default_catalog_config(config, :display_fields, :search_fields, :sorts)

            config.default_solr_params = {
              :qt => "search",
              :per_page => 10,
              :fq  => ['{!raw f=source_facet}archive']
            }
            
            config.add_facet_field "format", :label => "Format", :limit => 3, :open => true
            config.add_facet_field "pub_date_sort", :label => "Publication Date", :limit => 3, :range => {:segments => false }
            config.add_facet_field "author_facet", :label => "Author", :limit => 3
            config.add_facet_field "repository_facet", :label => "Repository", :limit => 5
            config.add_facet_field "location_facet", :label => "Location", :limit => 5
            config.add_facet_field "language_facet", :label => "Language", :limit => 5
            config.add_facet_field "subject_topic_facet", :label => "Subject", :limit => 10
            config.add_facet_field "subject_geo_facet", :label => "Subject (Region)", :limit => 10
            config.add_facet_field "subject_era_facet", :label => "Subject (Era)", :limit => 10
            config.add_facet_field "subject_form_facet", :label => "Subject (Genre)", :limit => 10
            config.add_facet_field "lc_1letter_facet", :label => "Call Number", :limit => 26, :open => false
            config.add_facet_field "lc_2letter_facet", :label => "Refine Call Number", :limit => 26

          when 'new_arrivals'
            default_catalog_config(config, :display_fields, :search_fields, :sorts)

            config.default_solr_params = {
              :qt => "search",
              :per_page => 10,
              :fq  => ["acq_dt:[#{(Time.now - 6.months).utc.iso8601} TO *]"]
            }


      config.add_facet_field 'acq_dt', :label => 'Acquisition Date', :open => true, :query => {
       :week_1 => { :label => 'within 1 Week', :fq => "acq_dt:[#{(Time.now - 1.weeks).utc.iso8601} TO *]" },
       :month_1 => { :label => 'within 1 Month', :fq => "acq_dt:[#{(Time.now - 1.months).utc.iso8601} TO *]" },
       :months_6 => { :label => 'within 6 Months', :fq => "acq_dt:[#{(Time.now - 6.months).utc.iso8601} TO *]" },

       :years_1 => { :label => 'within 1 Year', :fq => "acq_dt:[#{(Time.now - 1.years).utc.iso8601} TO *]" },
    }      
            config.add_facet_field "format", :label => "Format", :limit => 5, :open => true
            config.add_facet_field "pub_date_sort", :label => "Publication Date", :limit => 3, :range => {:segments => false}
            config.add_facet_field "author_facet", :label => "Author", :limit => 5
            config.add_facet_field "location_facet", :label => "Location", :limit => 5
            config.add_facet_field "language_facet", :label => "Language", :limit => 5
            config.add_facet_field "subject_topic_facet", :label => "Subject", :limit => 10
            config.add_facet_field "subject_geo_facet", :label => "Subject (Region)", :limit => 10
            config.add_facet_field "subject_era_facet", :label => "Subject (Era)", :limit => 10
            config.add_facet_field "subject_form_facet", :label => "Subject (Genre)", :limit => 10
            config.add_facet_field "lc_1letter_facet", :label => "Call Number", :limit => 26, :open => false
            config.add_facet_field "lc_2letter_facet", :label => "Refine Call Number", :limit => 26

          when 'catalog'
            default_catalog_config(config)


          when 'academic_commons'
            default_catalog_config(config, :solr_params, :search_fields)

            config.show.html_title = "title_display"
            config.show.heading = "title_display"
            config.show.display_type = "format"

            config.show.genre = "genre_facet"
            config.show.author = "author_display"

            config.index.show_link = "title_display"
            config.index.record_display_type = "format"

            config.add_facet_field 'author_facet', :label => 'Author', :open => true, :limit => 5
            config.add_facet_field "pub_date_facet", :label => "Publication Date", :limit => 3, :range => {:segments => false }
            config.add_facet_field 'department_facet', :label => 'Department', :limit => 5
            config.add_facet_field 'subject_facet', :label => 'Subject', :limit => 10
            config.add_facet_field 'genre_facet', :label => 'Content Type', :limit => 10
            config.add_facet_field 'series_facet', :label => 'Series', :limit => 10

            config.add_sort_field   'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
            config.add_sort_field   'pub_date_sort asc, title_sort asc', :label => 'Published Earliest'
            config.add_sort_field   'pub_date_sort desc, title_sort asc', :label => 'Published Latest'
            config.add_sort_field   'author_sort asc, title_sort asc', :label => 'Author A-Z'
            config.add_sort_field   'author_sort desc, title_sort asc', :label => 'Author Z-A'
            config.add_sort_field  'title_sort asc, pub_date_sort desc', :label =>  'Title A-Z'
            config.add_sort_field   'title_sort desc, pub_date_sort desc', :label => 'Title Z-A'

          end

          config.add_facet_fields_to_solr_request!


        end
      end
    end
  end

  def by_source_config
    @active_source = determine_active_source
    configure_search(@active_source)
  end


  def default_catalog_config(config, *elements)
    elements = [:solr_params, :display_fields, :facets, :search_fields, :sorts] if elements.empty?

    if elements.include?(:solr_params)

      config.default_solr_params = {
        :qt => "search",
        :per_page => 10
      }
    end
  
    if elements.include?(:display_fields)
      config.show.html_title = "title_display"
      config.show.heading = "title_display"
      config.show.display_type = "format"

      config.index.show_link = "title_display"
      config.index.record_display_type = ''

    end

    if elements.include?(:facets)
      config.add_facet_field "format", :label => "Format", :limit => 5, :open => true
      config.add_facet_field "pub_date_sort", :label => "Publication Date", :limit => 3, :range => {:segments => false}
      config.add_facet_field "author_facet", :label => "Author", :limit => 5
      config.add_facet_field 'acq_dt', :label => 'Acquisition Date', :query => {
       :week_1 => { :label => 'within 1 Week', :fq => "acq_dt:[#{(Time.now - 1.weeks).utc.iso8601} TO *]" },
       :month_1 => { :label => 'within 1 Month', :fq => "acq_dt:[#{(Time.now - 1.months).utc.iso8601} TO *]" },
       :months_6 => { :label => 'within 6 Months', :fq => "acq_dt:[#{(Time.now - 6.months).utc.iso8601} TO *]" },

       :years_1 => { :label => 'within 1 Year', :fq => "acq_dt:[#{(Time.now - 1.years).utc.iso8601} TO *]" },
    }      
      config.add_facet_field "location_facet", :label => "Location", :limit => 5
      config.add_facet_field "language_facet", :label => "Language", :limit => 5
      config.add_facet_field "subject_topic_facet", :label => "Subject", :limit => 10
      config.add_facet_field "subject_geo_facet", :label => "Subject (Region)", :limit => 10
      config.add_facet_field "subject_era_facet", :label => "Subject (Era)", :limit => 10
      config.add_facet_field "subject_form_facet", :label => "Subject (Genre)", :limit => 10
      config.add_facet_field "lc_1letter_facet", :label => "Call Number", :limit => 26
      config.add_facet_field "lc_2letter_facet", :label => "Refine Call Number", :limit => 26
    end

    if elements.include?(:search_fields) 

      config.add_search_field('title') do |field|
        # solr_parameters hash are sent to Solr as ordinary url query params. 
        field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

        # :solr_local_parameters will be sent using Solr LocalParams
        # syntax, as eg {! qf=$title_qf }. This is neccesary to use
        # Solr parameter de-referencing like $title_qf.
        # See: http://wiki.apache.org/solr/LocalParams
        field.solr_local_parameters = { 
          :qf => '$title_qf',
          :pf => '$title_pf'
        }
      end
      
      config.add_search_field('journal_title') do |field|
        # solr_parameters hash are sent to Solr as ordinary url query params. 
        field.solr_parameters = { :'spellcheck.dictionary' => 'title', :fq => ['format:Journal\/Periodical'] }

        # :solr_local_parameters will be sent using Solr LocalParams
        # syntax, as eg {! qf=$title_qf }. This is neccesary to use
        # Solr parameter de-referencing like $title_qf.
        # See: http://wiki.apache.org/solr/LocalParams
        field.solr_local_parameters = { 
          :qf => '$title_qf',
          :pf => '$title_pf'
        }
      end

      config.add_search_field('author') do |field|
        field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
        field.solr_local_parameters = { 
          :qf => '$author_qf',
          :pf => '$author_pf'
        }
      end
      
      ## Specifying a :qt only to show it's possible, and so our internal automated
      ## tests can test it. In this case it's the same as 
      ## config[:default_solr_parameters][:qt], so isn't actually neccesary. 
      config.add_search_field('subject') do |field|
        field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
        field.qt = 'search'
        field.solr_local_parameters = { 
          :qf => '$subject_qf',
          :pf => '$subject_pf'
        }
      end

    end


    if elements.include?(:sorts)
      config.add_sort_field   'score desc, pub_date_sort desc, title_sort asc', :label => 'Relevance'
      config.add_sort_field  'acq_dt asc, title_sort asc', :label =>  'Acquired Earliest'
      config.add_sort_field   'acq_dt desc, title_sort asc', :label => 'Acquired Latest'
      config.add_sort_field   'pub_date_sort asc, title_sort asc', :label => 'Published Earliest'
      config.add_sort_field   'pub_date_sort desc, title_sort asc', :label => 'Published Latest'
      config.add_sort_field   'author_sort asc, title_sort asc', :label => 'Author A-Z'
      config.add_sort_field   'author_sort desc, title_sort asc', :label => 'Author Z-A'
      config.add_sort_field  'title_sort asc, pub_date_sort desc', :label =>  'Title A-Z'
      config.add_sort_field   'title_sort desc, pub_date_sort desc', :label => 'Title Z-A'
    end

  end


  protected
  def log_additional_data
    request.env["exception_notifier.url"] = {
      url: "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
    }
  end

end


module Spectrum
  module Engines
    class Solr
      include ActionView::Helpers::NumberHelper
      include Rails.application.routes.url_helpers
      Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options

      include Blacklight::Configurable
      include LocalSolrHelperExtension

      attr_reader :source, :documents, :search, :errors, :debug_mode, :debug_entries
      attr_accessor :params



      def initialize(original_options = {})
        solr_search_params_logic << :add_advanced_search_to_solr
        solr_search_params_logic << :add_range_limit_params

        options = original_options.to_hash.deep_clone
        @source = options.delete('source') || options.delete(:source) || raise('Must specify source')
        options.delete(:source)
        @debug_mode = options.delete(:debug_mode) || options.delete('debug_mode') || false
        @debug_entries = Hash.arbitrary_depth
        @current_user = options.delete('current_user')
        @search_url = options.delete('search_url')

        # allow pass-in override solr url
        @solr_url = options.delete('solr_url')
        Blacklight.solr = Solr.generate_rsolr(@source, @solr_url)
        @config =  Solr.generate_config(@source)
        @params = options
        @params.symbolize_keys!
        Rails.logger.info "[Spectrum][Solr] source: #{@source} params: #{@params}"

        begin
          perform_search
        rescue Exception => e
          Rails.logger.error "[Spectrum][Solr] error: #{e.message}"
          @errors = e.message
        end

      end


      def results
        documents
      end

      def search_path
        @search_url || by_source_search_link(@params)
      end

      def total_items
        @search && (@search['response'] && @search['response']['numFound']).to_i
      end

      def blacklight_config
        @config
      end

      def blacklight_config=(config)
        @config = config
      end

      def successful?
        @errors.nil?
      end


      private



      def by_source_search_link(params = {})
        case @source
        when 'catalog'
          catalog_index_path(params)
        when 'academic_commons', 'ac_dissertations'
          academic_commons_index_path(params)
        when 'journals'
          journals_index_path(params)
        when 'databases'
          databases_index_path(params)
        when 'new_arrivals'
          new_arrivals_index_path(params)
        when 'archives'
          archives_index_path(params)
        end

      end

      def perform_search()
        extra_controller_params = {}

        if @debug_mode
          extra_controller_params.merge!('debugQuery' => 'true')

            debug_results = lambda do |*args|       
              @debug_entries['solr'] = [] if @debug_entries['solr'] == {}
              event =   ActiveSupport::Notifications::Event.new(*args)

              hashed_event = {
                debug_uri: event.payload[:uri].to_s.gsub('wt=ruby&',"wt=xml&")+"&debugQuery=true",

              }

              @debug_entries['solr'] << hashed_event if @current_user && @current_user.has_role?('site', 'admin')
            end

            ActiveSupport::Notifications.subscribed(debug_results, "execute.rsolr_client") do |*args|
              
              @search, @documents = get_search_results(@params, extra_controller_params)
              @debug_entries['solr'] = []  if @debug_entries['solr'] == {}
              hashed_event = {
                timing: @search['debug']['timing'],
                parsedquery: @search['debug']['parsedquery'].to_s,
                params: @search['params']
              }
              
              @debug_entries['solr'] << hashed_event
            end
            
          else
            @search, @documents = get_search_results(@params, extra_controller_params)

        end

        return self
      end

      def self.generate_rsolr(source, solr_url = nil)
        if source.in?("academic_commons", "ac_dissertations")
          RSolr.connect(:url => APP_CONFIG['ac2_solr_url'])
        elsif (solr_url)
          RSolr.connect(:url => solr_url)
        else
          RSolr.connect(Blacklight.solr_config) 
        end
      end

      def self.add_search_fields(config, *fields)
        if fields.include?('title')
          config.add_search_field('title') do |field|
            field.show_in_dropdown = true
            field.solr_parameters = { :'spellcheck.dictionary' => 'title' }
            field.solr_local_parameters = { 
              :qf => '$title_qf',
              :pf => '$title_pf'
            }
          end
        end
          
        if fields.include?('journal_title')
          config.add_search_field('journal_title') do |field|
            field.show_in_dropdown = true
            field.solr_parameters = { :'spellcheck.dictionary' => 'title', :fq => ['format:Journal\/Periodical'] }
            field.solr_local_parameters = { 
              :qf => '$title_qf',
              :pf => '$title_pf'
            }
          end
        end

        if fields.include?('author')
          config.add_search_field('author') do |field|
            field.show_in_dropdown = true
            field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
            field.solr_local_parameters = { 
              :qf => '$author_qf',
              :pf => '$author_pf'
            }
          end
        end
          
        if fields.include?('subject')
          config.add_search_field('subject') do |field|
            field.show_in_dropdown = true
            field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
            field.qt = 'search'
            field.solr_local_parameters = { 
              :qf => '$subject_qf',
              :pf => '$subject_pf'
            }
          end
        end
      end

      def self.default_catalog_config(config, *elements)
        elements = [:solr_params, :display_fields, :facets, :search_fields, :sorts] if elements.empty?

        if elements.include?(:solr_params)

          config.default_solr_params = {
            :qt => "search",
            :rows => 10
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
          add_search_fields(config, 'title', 'journal_title', 'author', 'subject')

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

      def self.generate_config(source)


        if source.in?('quicksearch','ebooks','dissertations')
          self.blacklight_config = Blacklight::Configuration.new do |config|
            default_catalog_config(config)
            config.default_solr_params = {
              :qt => 'search',
              :rows => 10
            }

            config.add_search_field 'all_fields', :label => 'All Fields'
        
            config.spell_max = 0
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
            when 'catalog_ebooks'
              default_catalog_config(config, :display_fields, :facets, :search_fields, :sorts)
              config.default_solr_params = {
                :qt => "search",
                :rows => 15,
                :fq  => ['{!raw f=format}Book', '{!raw f=format}Online']
              }
            when 'catalog_dissertations'
              default_catalog_config(config, :display_fields, :facets, :search_fields, :sorts)
              config.default_solr_params = {
                :qt => "search",
                :rows => 15,
                :fq  => ['{!raw f=format}Thesis']
              }
            when 'journals'
              default_catalog_config(config, :display_fields, :sorts)

              config.default_solr_params = {
                :qt => "search",
                :rows => 10,
                :fq  => ['{!raw f=source_facet}ejournal']
              }

              config.add_facet_field "language_facet", :label => "Language", :limit => 5, :open => true
              config.add_facet_field "subject_topic_facet", :label => "Subject", :limit => 10
              config.add_facet_field "subject_geo_facet", :label => "Subject (Region)", :limit => 10
              config.add_facet_field "subject_era_facet", :label => "Subject (Era)", :limit => 10
              config.add_facet_field "subject_form_facet", :label => "Subject (Genre)", :limit => 10
              config.add_facet_field 'title_first_facet', :label => "Starts With"
              add_search_fields(config, 'title',  'author', 'subject')
              config[:unapi] = {
                'oai_dc_xml' => { :content_type => 'text/xml' }
              }

            when 'databases'
              default_catalog_config(config, :display_fields)


              config.default_solr_params = {
                :qt => "search",
                :rows => 10,
                :fq  => ['{!raw f=source_facet}database']
              }

              config[:unapi] = {
                'oai_dc_xml' => { :content_type => 'text/xml' }
              }

              config.add_facet_field "database_hilcc_facet", :label => "Discipline", :limit => 5, :open => true
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
              config.add_sort_field  'title_sort asc, pub_date_sort desc', :label =>  'Title A-Z'
              config.add_sort_field   'title_sort desc, pub_date_sort desc', :label => 'Title Z-A'

              add_search_fields(config, 'title',  'author', 'subject')
              config[:unapi] = {
                'oai_dc_xml' => { :content_type => 'text/xml' }
              }


            when 'archives'
              default_catalog_config(config, :display_fields,  :sorts)

              config.default_solr_params = {
                :qt => "search",
                :rows => 10,
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
              add_search_fields(config, 'title',  'author', 'subject')

            when 'new_arrivals'
              default_catalog_config(config, :display_fields, :search_fields, :sorts)

              config.default_solr_params = {
                :qt => "search",
                :rows => 10,
                :fq  => ["acq_dt:[#{(Time.now - 6.months).utc.iso8601} TO *]"]
              }


        config.add_facet_field 'acq_dt', :label => 'Acquisition Date', :open => true, :query => {
         :week_1 => { :label => 'within 1 Week', :fq => "acq_dt:[#{(Date.today - 1.weeks).to_datetime.iso8601} TO *]" },
         :month_1 => { :label => 'within 1 Month', :fq => "acq_dt:[#{(Date.today - 1.months).to_datetime.iso8601} TO *]" },
         :months_6 => { :label => 'within 6 Months', :fq => "acq_dt:[#{(Date.today - 6.months).to_datetime.iso8601} TO *]" },

         :years_1 => { :label => 'within 1 Year', :fq => "acq_dt:[#{(Date.today - 1.years).to_datetime.iso8601} TO *]" },
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

            when 'ac_dissertations'
              default_catalog_config(config,:search_fields)


              config.default_solr_params = {
                :qt => "search",
                :rows => 10,
                :fq => ['{!raw f=genre_facet}Dissertations']
              }

              config.show.html_title = "title_display"
              config.show.heading = "title_display"
              config.show.display_type = "format"

              config.show.genre = "genre_facet"
              config.show.author = "author_display"

              config.index.show_link = "title_display"
              config.index.record_display_type = "format"

              config.add_facet_field 'author_facet', :label => 'Author', :open => true, :limit => 5
              config.add_facet_field "pub_date_sort", :label => "Publication Date", :limit => 3, :range => {:segments => false }
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
              config.add_facet_field "pub_date_sort", :label => "Publication Date", :limit => 3, :range => {:segments => false }
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
  end

end


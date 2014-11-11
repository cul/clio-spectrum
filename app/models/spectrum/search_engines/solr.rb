module Spectrum
  module SearchEngines
    class Solr
      include ActionView::Helpers::NumberHelper
      include Rails.application.routes.url_helpers
      Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options

      include Blacklight::Configurable
      include LocalSolrHelperExtension

      # # Because BL core includes it, we're obliged to?
      # include ActiveSupport::Benchmarkable

      attr_reader :source, :documents, :search, :errors, :debug_mode, :debug_entries
      attr_accessor :params

      # Because Blacklight::SolrHelper calls benchmark(), we need
      # 'logger' to be available.  In Controllers, it is, but here
      # it is not, unless I do this.
      def logger
        Rails.logger
      end

      # Invoked when ApplicationController::blacklight_search() calls:
      #     search_engine = Spectrum::SearchEngines::Solr.new(options)
      def initialize(original_options = {})
        # this "solr_search_params_logic" is used when querying via our Solr engine.
        # queries using standard blacklight functions have their own config in CatalogController
        unless solr_search_params_logic.include? :add_advanced_search_to_solr
          solr_search_params_logic << :add_advanced_search_to_solr
        end
        unless solr_search_params_logic.include? :add_range_limit_params
          solr_search_params_logic << :add_range_limit_params
        end

        options = original_options.to_hash.deep_clone
        @source = options.delete('source') || options.delete(:source) || fail('Must specify source')
        options.delete(:source)
        @debug_mode = options.delete(:debug_mode) || options.delete('debug_mode') || false
        @debug_entries = Hash.arbitrary_depth
        @current_user = options.delete('current_user')
        @search_url = options.delete('search_url')

        # allow pass-in override solr url
        @solr_url = options.delete('solr_url')
        blacklight_solr
        blacklight_solr_config
        @params = options
        @params.symbolize_keys!
        Rails.logger.info "[Spectrum][Solr] source: #{@source} params: #{@params}"
# raise
        begin
          # here's the actual search, defined below in this file
          perform_search
        rescue => ex
          Rails.logger.error "#{self.class}##{__method__} [Spectrum][Solr] error: #{ex.message}"
          @errors = ex.message
          # Re-raising the same error will be caught by Blacklight::Base.rsolr_request_error()
          # which will log, flash and redirect_to root_path.  We don't want that.
          # raise ex
          raise 'Error searching Solr'
        end
      end

      def blacklight_solr
        @solr ||= Solr.generate_rsolr(@source, @solr_url)
      end

      def blacklight_solr_config
        @config ||= Solr.generate_config(@source)
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
        when 'catalog_ebooks'
          params['f'] ||= {}
          params['f']['format'] = %w(Book Online)
          catalog_index_path(params)

        when 'catalog_dissertations'
          params['f'] ||= {}
          params['f']['format'] = ['Thesis']
          catalog_index_path(params)
        when 'academic_commons'
          academic_commons_index_path(params)
        when 'ac_dissertations'
          params['f'] ||= {}
          params['f']['genre_facet'] = ['Dissertations']
          academic_commons_index_path(params)
        when 'dcv'
          dcv_index_path(params)
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

      def perform_search
        extra_controller_params = {}

        if @debug_mode

          extra_controller_params.merge!('debugQuery' => 'true')

          debug_results = lambda do |*args|
            @debug_entries['solr'] = [] if @debug_entries['solr'] == {}
            event =   ActiveSupport::Notifications::Event.new(*args)

            hashed_event = {
              debug_uri: event.payload[:uri].to_s.gsub('wt=ruby&', 'wt=xml&') + '&debugQuery=true',
              debug_uri_unescaped: CGI.unescape(event.payload[:uri].to_s.gsub('wt=ruby&', 'wt=xml&') + '&debugQuery=true'),

            }

            @debug_entries['solr'] << hashed_event if @current_user && @current_user.has_role?('site', 'admin')
          end

          ActiveSupport::Notifications.subscribed(debug_results, 'execute.rsolr_client') do |*args|
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
          # use blacklight gem to run the actual search against Solr,
          # call Blacklight::SolrHelper::get_search_results()
          @search, @documents = get_search_results(@params, extra_controller_params)
        end

        self
      end

      def self.generate_rsolr(source, solr_url = nil)
        if source.in?('academic_commons', 'ac_dissertations')
          RSolr.connect(url: APP_CONFIG['ac2_solr_url'])
        elsif source.in?('dcv')
          RSolr.connect(url: APP_CONFIG['dcv_solr_url'])
        elsif solr_url
          RSolr.connect(url: solr_url)
        else
          RSolr.connect(Blacklight.solr_config)
        end
      end

      # Default config has already been created, now add in the field-scoped
      # config settings specific to each fielded search being offered
      def self.add_search_fields(config, *fields)
        if fields.include?('title')
          config.add_search_field('title') do |field|
            field.show_in_dropdown = true
            # field.solr_parameters = { :'spellcheck.dictionary' => 'title' }
            field.solr_local_parameters = {
              qf: '$title_qf',
              pf: '$title_pf'
            }
          end
        end

        if fields.include?('title_start')
          config.add_search_field('title_start') do |field|
            field.show_in_dropdown = true
            field.label = 'Title Begins With'
            # field.solr_parameters = { :'spellcheck.dictionary' => 'title' }
            field.solr_local_parameters = {
              qf: '$title_start_qf',
              pf: '$title_start_pf'
            }
          end
        end

        if fields.include?('journal_title')
          config.add_search_field('journal_title') do |field|
            field.show_in_dropdown = true
            # The field-specific solr_parameters defined here will
            # replace the source-specific default_solr_params when
            # a search by this field is in effect.
            field_fq = ['format:Journal\/Periodical']
            # So - copy in any source-specific solr param values.
            field_fq.push(config.default_solr_params[:fq]) if
                config.default_solr_params[:fq]

            field.solr_parameters = { fq: field_fq }

            # field.solr_parameters = { :fq => ['format:Journal\/Periodical'] }

            # This fix does not work.  It refers to, instead of copying, the default.
            # default_fq = config.default_solr_params[:fq] ||= []
            # field.solr_parameters = {:fq => default_fq.push('format:Journal\/Periodical') }
            field.solr_local_parameters = {
              qf: '$title_qf',
              pf: '$title_pf'
            }
          end
        end

        if fields.include?('series_title')
          config.add_search_field('series_title') do |field|
            field.show_in_dropdown = true
            field.label = 'Series'
            field.solr_local_parameters = {
              qf: 'title_series_txt',
              pf: 'title_series_txt'
            }
          end
        end

        if fields.include?('title_starts_with')
          config.add_search_field('title_starts_with') do |field|
            field.show_in_dropdown = true
            field.label = 'Title Begins With'
            field.solr_local_parameters = {
              qf: '$title_start_qf',
              pf: '$title_start_pf'
            }
          end
        end

        if fields.include?('author')
          config.add_search_field('author') do |field|
            field.show_in_dropdown = true
            # field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
            field.solr_local_parameters = {
              qf: '$author_qf',
              pf: '$author_pf'
            }
          end
        end

        if fields.include?('subject')
          config.add_search_field('subject') do |field|
            field.show_in_dropdown = true
            # field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
            field.qt = 'search'
            field.solr_local_parameters = {
              qf: '$subject_qf',
              pf: '$subject_pf'
            }
          end
        end

        if fields.include?('form_genre')
          config.add_search_field('form_genre') do |field|
            field.show_in_dropdown = true
            field.qt = 'search'
            field.label = 'Form/Genre'
            field.solr_local_parameters = {
              qf: 'subject_form_txt',
              pf: 'subject_form_txt'
            }
          end
        end

        if fields.include?('publication_place')
          config.add_search_field('publication_place') do |field|
            field.show_in_dropdown = true
            field.qt = 'search'
            field.solr_local_parameters = {
              qf: 'pub_place_txt',
              pf: 'pub_place_txt'
            }
          end
        end

        if fields.include?('publisher')
          config.add_search_field('publisher') do |field|
            field.show_in_dropdown = true
            field.qt = 'search'
            field.solr_local_parameters = {
              qf: 'pub_name_txt',
              pf: 'pub_name_txt'
            }
          end
        end

        if fields.include?('publication_year')
          config.add_search_field('publication_year') do |field|
            field.show_in_dropdown = true
            field.qt = 'search'
            field.solr_local_parameters = {
              qf: 'pub_year_txt',
              pf: 'pub_year_txt'
            }
          end
        end

        if fields.include?('isbn')
          config.add_search_field('isbn') do |field|
            field.show_in_dropdown = true
            field.qt = 'search'
            field.label = 'ISBN'
            field.solr_local_parameters = {
              qf: 'isbn_txt',
              pf: 'isbn_txt'
            }
          end
        end

        if fields.include?('issn')
          config.add_search_field('issn') do |field|
            field.show_in_dropdown = true
            field.qt = 'search'
            field.label = 'ISSN'
            field.solr_local_parameters = {
              qf: 'issn_txt',
              pf: 'issn_txt'
            }
          end
        end

        if fields.include?('call_number')
          config.add_search_field('call_number') do |field|
            field.show_in_dropdown = true
            field.qt = 'search'
            field.solr_local_parameters = {
              qf: 'location_call_number_txt',
              pf: 'location_call_number_txt'
            }
          end
        end

        if fields.include?('location')
          config.add_search_field('location') do |field|
            field.show_in_dropdown = true
            field.qt = 'search'
            field.solr_local_parameters = {
              qf: 'location_txt',
              pf: 'location_txt'
            }
          end
        end

        if fields.include?('dcv_title')
          config.add_search_field('title') do |field|
            field.show_in_dropdown = true
            field.solr_local_parameters = {
              qf: 'title_teim',
              pf: 'title_teim'
            }
          end
        end

        if fields.include?('dcv_name')
          config.add_search_field('name') do |field|
            field.show_in_dropdown = true
            field.solr_local_parameters = {
              qf: 'lib_name_teim',
              pf: 'lib_name_teim'
            }
          end
        end

      end

      # Supply default config values for the specified config keys (elements).
      # By nothing is specified, supply defaults for ALL standard elements.
      def self.default_catalog_config(config, *elements)
        elements = [:solr_params, :display_fields, :facets, :search_fields, :sorts] if elements.empty?

        if elements.include?(:solr_params)
          config.default_solr_params = {
            qt: 'search',
            rows: 25
          }
        end

        if elements.include?(:display_fields)
          config.show.title_field = 'title_display'
          config.show.title_field = 'title_display'
          config.show.display_type_field = 'format'

          config.index.title_field = 'title_display'
          config.index.display_type_field = ''
        end

        if elements.include?(:facets)
          config.add_facet_field 'format',
                                 # BL5 - "open" becomes "collapse"
                                 # label: 'Format', limit: 5, open: true
                                 label: 'Format', limit: 5, collapse: false
          # NEXT-698 - :segments key is searched for at top, not within range
          config.add_facet_field 'pub_date_sort',
                                 label: 'Publication Date', limit: 3,
                                 range: { segments: false }, segments: false
          config.add_facet_field 'author_facet',
                                 label: 'Author', limit: 5
          config.add_facet_field 'acq_dt',
                                 label: 'Acquisition Date',
                                 query: {
                                   week_1: { label: 'within 1 Week', fq: "acq_dt:[#{(Date.today - 1.weeks).to_datetime.utc.to_solr_s} TO *]" },
                                   month_1: { label: 'within 1 Month', fq: "acq_dt:[#{(Date.today - 1.months).to_datetime.utc.to_solr_s} TO *]" },
                                   months_6: { label: 'within 6 Months', fq: "acq_dt:[#{(Date.today - 6.months).to_datetime.utc.to_solr_s} TO *]" },
                                   years_1: { label: 'within 1 Year', fq: "acq_dt:[#{(Date.today - 1.years).to_datetime.utc.to_solr_s} TO *]" },
                                 }
          config.add_facet_field 'location_facet',
                                 label: 'Location', limit: 5
          config.add_facet_field 'language_facet',
                                 label: 'Language', limit: 5
          config.add_facet_field 'subject_topic_facet',
                                 label: 'Subject', limit: 10
          config.add_facet_field 'subject_geo_facet',
                                 label: 'Subject (Region)', limit: 10
          config.add_facet_field 'subject_era_facet',
                                 label: 'Subject (Era)', limit: 10
          config.add_facet_field 'subject_form_facet',
                                 label: 'Subject (Genre)', limit: 10
          config.add_facet_field 'lc_1letter_facet',
                                 label: 'Call Number', limit: 30
          config.add_facet_field 'lc_subclass_facet',
                                 label: 'Refine Call Number', limit: 500
        end

        if elements.include?(:search_fields)
          add_search_fields(config, 'title', 'journal_title', 'series_title',
                            'title_starts_with', 'author', 'subject', 'form_genre',
                            'publication_place', 'publisher', 'publication_year',
                            'isbn', 'issn', 'call_number', 'location')
        end

        if elements.include?(:sorts)
          config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc',
                                label: 'Relevance'
          config.add_sort_field 'acq_dt asc, title_sort asc',
                                label: 'Acquired Earliest'
          config.add_sort_field 'acq_dt desc, title_sort asc',
                                label: 'Acquired Latest'
          config.add_sort_field 'pub_date_sort asc, title_sort asc',
                                label: 'Published Earliest'
          config.add_sort_field 'pub_date_sort desc, title_sort asc',
                                label: 'Published Latest'
          config.add_sort_field 'author_sort asc, title_sort asc',
                                label: 'Author A-Z'
          config.add_sort_field 'author_sort desc, title_sort asc',
                                label: 'Author Z-A'
          config.add_sort_field 'title_sort asc, pub_date_sort desc',
                                label: 'Title A-Z'
          config.add_sort_field 'title_sort desc, pub_date_sort desc',
                                label: 'Title Z-A'
        end
      end

      def self.generate_config(source)
        # If we're in one of the hybrid-source bento-box searches....
        if source.in?('quicksearch', 'ebooks', 'dissertations')
          self.blacklight_config = Blacklight::Configuration.new do |config|

            # Add the "All Fields" seach field first, then append all the other default searches
            # NEXT-705 - "All Fields" should be default, and should be first option
            config.add_search_field 'all_fields', label: 'All Fields'
            default_catalog_config(config)

            # override defaults to lower rows from 25 to 10 for bento-box searches
            config.default_solr_params = {
              qt: 'search',
              rows: 10
            }

            config.per_page = [10, 25, 50, 100]
            config.spell_max = 0
          end
        # Else, we're in one of the single-source searches....
        else
          self.blacklight_config = Blacklight::Configuration.new do |config|

            config.default_solr_params = {
              qt: 'search',
              rows: 25
            }

            # These apply to any config for any source
            config.per_page = [10, 25, 50, 100]
            config.spell_max = 0

            config.add_search_field 'all_fields', label: 'All Fields'
            config.document_solr_request_handler = 'document'

            case source
            when 'catalog'
              default_catalog_config(config)

            when 'catalog_ebooks'
              default_catalog_config(config, :display_fields, :facets, :search_fields, :sorts)
              config.default_solr_params = {
                qt: 'search',
                rows: 25,
                fq: ['{!raw f=format}Book', '{!raw f=format}Online']
              }
            when 'catalog_dissertations'
              default_catalog_config(config, :display_fields, :facets, :search_fields, :sorts)
              config.default_solr_params = {
                qt: 'search',
                rows: 25,
                fq: ['{!raw f=format}Thesis']
              }
            when 'journals'
              default_catalog_config(config, :display_fields, :sorts)

              config.default_solr_params = {
                qt: 'search',
                rows: 25,
                fq: ['{!raw f=source_facet}ejournal']
              }

              # experiments only... remove for prod...
              # this reveals that about 9K records with data-source E-Journals
              # are NOT of ofrmat "Journal/Periodical"
              # config.add_facet_field "format",
              #    :label => "Format", :limit => 5, :open => true

              config.add_facet_field 'language_facet',
                                     label: 'Language',
                                     # BL5 - "open" becomes "collapse"
                                     # limit: 5, open: true                                     
                                     limit: 5, collapse: false
              config.add_facet_field 'subject_topic_facet',
                                     label: 'Subject',
                                     limit: 10
              config.add_facet_field 'subject_geo_facet',
                                     label: 'Subject (Region)',
                                     limit: 10
              config.add_facet_field 'subject_era_facet',
                                     label: 'Subject (Era)',
                                     limit: 10
              config.add_facet_field 'subject_form_facet',
                                     label: 'Subject (Genre)',
                                     limit: 10
              config.add_facet_field 'title_first_facet',
                                     label: 'Starts With'

              add_search_fields(config, 'title', 'title_starts_with',
                                'subject', 'issn')

            when 'databases'
              default_catalog_config(config, :display_fields)

              config.default_solr_params = {
                qt: 'search',
                rows: 25,
                fq: ['{!raw f=source_facet}database']
              }

              config.add_facet_field 'database_discipline_facet',
                                     # BL5 - "open" becomes "collapse"
                                     # label: 'Discipline', limit: 5, open: true
                                     label: 'Discipline', limit: 5, collapse: false
              config.add_facet_field 'database_resource_type_facet',
                                     label: 'Resource Type', limit: 5
              config.add_facet_field 'language_facet',
                                     label: 'Language', limit: 5
              config.add_facet_field 'subject_topic_facet',
                                     label: 'Subject', limit: 10
              config.add_facet_field 'subject_geo_facet',
                                     label: 'Subject (Region)', limit: 10
              config.add_facet_field 'subject_era_facet',
                                     label: 'Subject (Era)', limit: 10
              config.add_facet_field 'subject_form_facet',
                                     label: 'Subject (Genre)', limit: 10
              config.add_facet_field 'lc_1letter_facet',
                                     # BL5 - "open" becomes "collapse"
                                     # label: 'Call Number', limit: 26, open: false
                                     label: 'Call Number', limit: 30, collapse: true
              config.add_facet_field 'lc_subclass_facet',
                                     label: 'Refine Call Number', limit: 500
              config.add_facet_field 'title_first_facet',
                                     label: 'Starts With'

              config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc',
                                    label: 'Relevance'
              config.add_sort_field 'title_sort asc, pub_date_sort desc',
                                    label: 'Title A-Z'
              config.add_sort_field 'title_sort desc, pub_date_sort desc',
                                    label: 'Title Z-A'
              # NEXT-1046 - Sort databases by acquisition date
              config.add_sort_field 'acq_dt asc, title_sort asc',
                                    label: 'Acquired Earliest'
              config.add_sort_field 'acq_dt desc, title_sort asc',
                                    label: 'Acquired Latest'

              add_search_fields(config, 'title',  'author', 'subject')

            when 'archives'
              default_catalog_config(config, :display_fields,  :sorts)

              config.default_solr_params = {
                qt: 'search',
                rows: 25,
                fq: ['{!raw f=source_facet}archive']
              }

              config.add_facet_field 'format',
                                     # label: 'Format', limit: 3, open: true
                                     label: 'Format', limit: 3, collapse: false
              # NEXT-698 - :segments key is searched for at top, not within range
              config.add_facet_field 'pub_date_sort',
                                     label: 'Publication Date', limit: 3,
                                     range: { segments: false }, segments: false
              config.add_facet_field 'author_facet',
                                     label: 'Author', limit: 3
              config.add_facet_field 'repository_facet',
                                     label: 'Repository', limit: 5
              config.add_facet_field 'location_facet',
                                     label: 'Location', limit: 5
              config.add_facet_field 'language_facet',
                                     label: 'Language', limit: 5
              config.add_facet_field 'subject_topic_facet',
                                     label: 'Subject', limit: 10
              config.add_facet_field 'subject_geo_facet',
                                     label: 'Subject (Region)', limit: 10
              config.add_facet_field 'subject_era_facet',
                                     label: 'Subject (Era)', limit: 10
              config.add_facet_field 'subject_form_facet',
                                     label: 'Subject (Genre)', limit: 10
              config.add_facet_field 'lc_1letter_facet',
                                     # label: 'Call Number', limit: 26, open: false
                                     label: 'Call Number', limit: 30, collapse: true
              config.add_facet_field 'lc_subclass_facet',
                                     label: 'Refine Call Number', limit: 500

              add_search_fields(config, 'title',  'author', 'subject')

            when 'new_arrivals'
              # has to come before default_catalog_config(), because the
              # default search_fields define field-specific solr-params,
              # which need to read in source-default solr params
              # (e.g., to merge fq values)
              config.default_solr_params = {
                qt: 'search',
                rows: 25,
                # NEXT-845 - New Arrivals timeframe (6 month count == 1 year count)
                # :fq  => ["acq_dt:[#{(Date.today - 6.months).to_datetime.utc.to_solr_s} TO *]"]
                fq: ["acq_dt:[#{(Date.today - 1.year).to_datetime.utc.to_solr_s} TO *]"]
              }

              default_catalog_config(config, :display_fields, :search_fields, :sorts)

              config.add_facet_field 'acq_dt', 
                                    # label: 'Acquisition Date', open: true, 
                                    label: 'Acquisition Date', collapse: false, 
                                    query: {
                week_1: { label: 'within 1 Week', fq: "acq_dt:[#{(Date.today - 1.weeks).to_datetime.utc.to_solr_s} TO *]" },
                month_1: { label: 'within 1 Month', fq: "acq_dt:[#{(Date.today - 1.months).to_datetime.utc.to_solr_s} TO *]" },
                months_6: { label: 'within 6 Months', fq: "acq_dt:[#{(Date.today - 6.months).to_datetime.utc.to_solr_s} TO *]" },
                years_1: { label: 'within 1 Year', fq: "acq_dt:[#{(Date.today - 1.years).to_datetime.utc.to_solr_s} TO *]" },
              }
              config.add_facet_field 'format',
                                     # label: 'Format', limit: 5, open: true
                                     label: 'Format', limit: 5, collapse: false
              # NEXT-698 - :segments key is searched for at top, not within range
              config.add_facet_field 'pub_date_sort',
                                     label: 'Publication Date', limit: 3, range: { segments: false }, segments: false
              config.add_facet_field 'author_facet',
                                     label: 'Author', limit: 5
              config.add_facet_field 'location_facet',
                                     label: 'Location', limit: 5
              config.add_facet_field 'language_facet',
                                     label: 'Language', limit: 5
              config.add_facet_field 'subject_topic_facet',
                                     label: 'Subject', limit: 10
              config.add_facet_field 'subject_geo_facet',
                                     label: 'Subject (Region)', limit: 10
              config.add_facet_field 'subject_era_facet',
                                     label: 'Subject (Era)', limit: 10
              config.add_facet_field 'subject_form_facet',
                                     label: 'Subject (Genre)', limit: 10
              config.add_facet_field 'lc_1letter_facet',
                                     # label: 'Call Number', limit: 26, open: false
                                     label: 'Call Number', limit: 30, collapse: true
              config.add_facet_field 'lc_subclass_facet',
                                     label: 'Refine Call Number', limit: 500

            when 'ac_dissertations'
              default_catalog_config(config, :search_fields)

              config.default_solr_params = {
                qt: 'search',
                rows: 25,
                fq: ['{!raw f=genre_facet}Dissertations']
              }

              config.show.title_field = 'title_display'
              config.show.title_field = 'title_display'
              config.show.display_type_field = 'format'

              config.show.genre = 'genre_facet'
              config.show.author = 'author_display'

              config.index.title_field = 'title_display'
              config.index.display_type_field = 'format'

              config.add_facet_field 'author_facet',
                                     # label: 'Author', open: true, limit: 5
                                     label: 'Author', collapse: false, limit: 5
              # NEXT-698 - :segments key is searched for at top, not within range
              config.add_facet_field 'pub_date_sort',
                                     label: 'Publication Date', limit: 3,
                                     range: { segments: false }, segments: false
              config.add_facet_field 'department_facet',
                                     label: 'Department', limit: 5
              config.add_facet_field 'subject_facet',
                                     label: 'Subject', limit: 10
              config.add_facet_field 'genre_facet',
                                     label: 'Content Type', limit: 10
              config.add_facet_field 'series_facet',
                                     label: 'Series', limit: 10

              config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc',
                                    label: 'relevance'
              config.add_sort_field 'pub_date_sort asc, title_sort asc',
                                    label: 'Published Earliest'
              config.add_sort_field 'pub_date_sort desc, title_sort asc',
                                    label: 'Published Latest'
              config.add_sort_field 'author_sort asc, title_sort asc',
                                    label: 'Author A-Z'
              config.add_sort_field 'author_sort desc, title_sort asc',
                                    label: 'Author Z-A'
              config.add_sort_field 'title_sort asc, pub_date_sort desc',
                                    label: 'Title A-Z'
              config.add_sort_field 'title_sort desc, pub_date_sort desc',
                                    label: 'Title Z-A'

            when 'academic_commons'
              default_catalog_config(config, :solr_params, :search_fields)

              config.show.title_field = 'title_display'
              config.show.display_type_field = 'format'

              config.show.genre = 'genre_facet'
              config.show.author = 'author_display'

              config.index.title_field = 'title_display'
              config.index.display_type_field = 'format'

              config.add_facet_field 'author_facet',
                                     # label: 'Author', open: true, limit: 5
                                     label: 'Author', collapse: false, limit: 5
              config.add_facet_field 'pub_date_sort',
                                     label: 'Publication Date', limit: 3,
                                     range: { segments: false }, segments: false
              config.add_facet_field 'department_facet',
                                     label: 'Department', limit: 5
              config.add_facet_field 'subject_facet',
                                     label: 'Subject', limit: 10
              config.add_facet_field 'genre_facet',
                                     label: 'Content Type', limit: 10
              config.add_facet_field 'series_facet',
                                     label: 'Series', limit: 10

              config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc',
                                    label: 'relevance'
              config.add_sort_field 'pub_date_sort asc, title_sort asc',
                                    label: 'Published Earliest'
              config.add_sort_field 'pub_date_sort desc, title_sort asc',
                                    label: 'Published Latest'
              config.add_sort_field 'author_sort asc, title_sort asc',
                                    label: 'Author A-Z'
              config.add_sort_field 'author_sort desc, title_sort asc',
                                    label: 'Author Z-A'
              config.add_sort_field 'title_sort asc, pub_date_sort desc',
                                    label: 'Title A-Z'
              config.add_sort_field 'title_sort desc, pub_date_sort desc',
                                    label: 'Title Z-A'

            when 'dcv'

              # default_catalog_config(config, :solr_params, :search_fields)

              add_search_fields(config, 'dcv_title', 'dcv_name')

              config.default_solr_params = {
                qt: 'search',
                rows: 25,
                qf: 'all_text_teim',
                pf: 'all_text_teim',
              }

              config.show.title_field = 'title_display_ssm'

              config.show.display_type_field = 'lib_format_ssm'

              # config.show.genre = 'genre_facet'

              config.show.author = 'name_corporate_ssm'

              config.index.title_field = 'title_display_ssm'

              config.index.display_type_field = 'lib_format_ssm'

              config.add_facet_field 'lib_project_short_ssim',
                                     label: 'Digital Project', limit: 5
              config.add_facet_field 'lib_collection_sim',
                                     label: 'Collection', limit: 5
              config.add_facet_field 'lib_repo_short_ssim',
                                     label: 'Library Location', limit: 5
              config.add_facet_field 'lib_name_sim',
                                     label: 'Name', limit: 10
              config.add_facet_field 'lib_format_sim',
                                     label: 'Format', limit: 10

              config.add_sort_field 'score desc, title_si asc, lib_date_dtsi desc',
                                    label: 'relevance'
              config.add_sort_field 'title_si asc, lib_date_dtsi desc',
                                    label: 'Title A-Z'
              config.add_sort_field 'title_si desc, lib_date_dtsi desc',
                                    label: 'Title Z-A'

            end # case source

            config.add_facet_fields_to_solr_request!

          end # Blacklight::Configuration.new do

        end # if/else bento-box/single-source
      end # self.generate_config
    end # class Solr
  end # module SearchEngines
end # module Spectrum

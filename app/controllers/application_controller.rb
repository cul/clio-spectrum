class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 
  before_filter :trigger_debug_mode
  before_filter :by_source_config

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end


  def trigger_debug_mode
    if params['debug_mode'] == 'on'
      @debug_mode = true
    elsif params['debug_mode'] == 'off'
      @debug_mode = false
    else
      @debug_mode ||= session['debug_mode'] || false
    end
    params.delete('debug_mode')
    session['debug_mode'] = @debug_mode
    @debug_entries = Hash.arbitrary_depth

    default_debug
  end

  def default_debug
    @debug_entries['params'] =params
    @debug_entries['session'] = session
  end

  
  def determine_active_source
    if params['active_source']
      @active_source = params['active_source']
    else
      path_minus_advanced = request.path.to_s.gsub(/^\/advanced/, '')
      @active_source = case path_minus_advanced 
      when /^\/databases/
        'Databases'
      when /^\/new_arrivals/
        'New Arrivals'
      when /^\/catalog/
        'Catalog'
      when /^\/articles/
        'Articles'
      when /^\/ejournals/
        'eJournals'
      when /^\/dissertations/
        'Dissertations'
      when /^\/ebooks/
        'eBooks'
      when /^\/academic_commons/
        'Academic Commons'
      when /^\/library_web/
        'Library Web'
      when /^\/archives/
        'Archives'
      else
        params['active_source'] || 'Quicksearch'
      end
    end
  end




  private
  def configure_search(source)

    if source == "Academic Commons"
      Blacklight.solr = RSolr::Ext.connect(:url => APP_CONFIG[:ac2_solr_url])
    else
      Blacklight.solr = RSolr::Ext.connect(Blacklight.solr_config)
    end
    if self.respond_to?(:blacklight_config)
      if source.in?('Quicksearch','eBooks','Dissertations')
        self.blacklight_config = Blacklight::Configuration.new do |config|

          config.add_search_field 'all_fields', :label => 'All Fields'
      
          config.spell_max = 0
          default_catalog_config(config)
        end
      else
        self.blacklight_config = Blacklight::Configuration.new do |config|
          config.add_search_field 'all_fields', :label => 'All Fields'

          case source
          when 'eJournals'
            default_catalog_config(config, :display_fields, :sorts)

            config.default_solr_params = {
              :qt => "search",
              :per_page => 15,
              :fq  => ['{!raw f=source_facet}ejournal']
            }

            config.add_facet_field "language_facet", :label => "Language", :limit => 3
            config.add_facet_field "subject_topic_facet", :label => "Subject", :limit => 3
            config.add_facet_field "subject_geo_facet", :label => "Subject (Region)", :limit => 3
            config.add_facet_field "subject_era_facet", :label => "Subject (Era)", :limit => 3
            config.add_facet_field "subject_form_facet", :label => "Subject (Genre)", :limit => 3
            config.add_facet_field 'title_first_facet', :label => "Starts With"
            config[:unapi] = {
              'oai_dc_xml' => { :content_type => 'text/xml' }
            }

          when 'Databases'
            default_catalog_config(config, :display_fields, :sorts)

            config.default_solr_params = {
              :qt => "search",
              :per_page => 15,
              :fq  => ['{!raw f=source_facet}database']
            }

            config.add_facet_field "lc_1letter_facet", :label => "Call Number", :limit => 26, :open => false
            config.add_facet_field "lc_2letter_facet", :label => "Refine Call Number", :limit => 26
            config.add_facet_field "language_facet", :label => "Language", :limit => 3
            config.add_facet_field "subject_topic_facet", :label => "Subject", :limit => 3
            config.add_facet_field "subject_geo_facet", :label => "Subject (Region)", :limit => 3
            config.add_facet_field "subject_era_facet", :label => "Subject (Era)", :limit => 3
            config.add_facet_field "subject_form_facet", :label => "Subject (Genre)", :limit => 3
            config.add_facet_field 'title_first_facet', :label => "Starts With"
            config[:unapi] = {
              'oai_dc_xml' => { :content_type => 'text/xml' }
            }

          when 'Archives'
            default_catalog_config(config, :display_fields, :search_fields, :sorts)

            config.default_solr_params = {
              :qt => "search",
              :per_page => 15,
              :fq  => ['{!raw f=source_facet}archive']
            }
            
            config.add_facet_field "format", :label => "Format", :limit => 3
            config.add_facet_field "pub_date_sort", :label => "Publication Date", :limit => 3, :range => true
            config.add_facet_field "author_facet", :label => "Author", :limit => 3
            config.add_facet_field "repository_facet", :label => "Repository", :limit => 3
            config.add_facet_field "location_facet", :label => "Location", :limit => 3
            config.add_facet_field "author_facet", :label => "Author", :limit => 3
            config.add_facet_field "language_facet", :label => "Language", :limit => 3
            config.add_facet_field "subject_topic_facet", :label => "Subject", :limit => 3
            config.add_facet_field "subject_geo_facet", :label => "Subject (Region)", :limit => 3
            config.add_facet_field "subject_era_facet", :label => "Subject (Era)", :limit => 3
            config.add_facet_field "subject_form_facet", :label => "Subject (Genre)", :limit => 3
            config.add_facet_field "lc_1letter_facet", :label => "Call Number", :limit => 26, :open => false
            config.add_facet_field "lc_2letter_facet", :label => "Refine Call Number", :limit => 26

          when 'New Arrivals'
            default_catalog_config(config)

            config.default_solr_params = {
              :qt => "search",
              :per_page => 15,
              :fq  => ['{!raw f=acq_date_facet}Last 3 Months']
            }

          when 'Catalog'
            default_catalog_config(config)


          when 'Academic Commons'
            default_catalog_config(config, :solr_params, :search_fields)

            config.show.html_title = "title_display"
            config.show.heading = "title_display"
            config.show.display_type = "format"

            config.show.genre = "genre_facet"
            config.show.author = "author_display"

            config.index.show_link = "title_display"
            config.index.record_display_type = "format"

            config.add_facet_field 'author_facet', :label => 'Author'
            config.add_facet_field 'department_facet', :label => 'Department'
            config.add_facet_field 'subject_facet', :label => 'Subject'
            config.add_facet_field 'pub_date_facet', :label => 'Publication Date',:range => true
            config.add_facet_field 'genre_facet', :label => 'Content Type'
            config.add_facet_field 'series_facet', :label => 'Series'

            config.add_sort_field   'score desc, pub_date_sort desc, title_sort asc', :label => 'Relevance'
            config.add_sort_field   'pub_date_sort asc, title_sort asc', :label => 'Published Earliest'
            config.add_sort_field   'pub_date_sort desc, title_sort asc', :label => 'Published Latest'
            config.add_sort_field   'author_sort asc, title_sort asc', :label => 'Author A-Z'
            config.add_sort_field   'author_sort desc, title_sort asc', :label => 'Author Z-A'
            config.add_sort_field  'title_sort asc, pub_date_sort desc', :label =>  'Title A-Z'
            config.add_sort_field   'title_sort desc, pub_date_sort desc', :label => 'Title Z-A'

          end
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
        :per_page => 15
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
      config.add_facet_field "format", :label => "Format", :limit => 3
      config.add_facet_field "pub_date_sort", :label => "Publication Date", :limit => 3, :range => true
      config.add_facet_field "author_facet", :label => "Author", :limit => 3
      config.add_facet_field "acq_date_facet", :label => "Acquisition Date", :limit => 3
      config.add_facet_field "location_facet", :label => "Location", :limit => 3
      config.add_facet_field "language_facet", :label => "Language", :limit => 3
      config.add_facet_field "subject_topic_facet", :label => "Subject", :limit => 3
      config.add_facet_field "subject_geo_facet", :label => "Subject (Region)", :limit => 3
      config.add_facet_field "subject_era_facet", :label => "Subject (Era)", :limit => 3
      config.add_facet_field "subject_form_facet", :label => "Subject (Genre)", :limit => 3
      config.add_facet_field "lc_1letter_facet", :label => "Call Number", :limit => 26, :open => false
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
      config.add_sort_field  'acq_date_sort asc, title_sort asc', :label =>  'Acquired Earliest'
      config.add_sort_field   'acq_date_sort desc, title_sort asc', :label => 'Acquired Latest'
      config.add_sort_field   'pub_date_sort asc, title_sort asc', :label => 'Published Earliest'
      config.add_sort_field   'pub_date_sort desc, title_sort asc', :label => 'Published Latest'
      config.add_sort_field   'author_sort asc, title_sort asc', :label => 'Author A-Z'
      config.add_sort_field   'author_sort desc, title_sort asc', :label => 'Author Z-A'
      config.add_sort_field  'title_sort asc, pub_date_sort desc', :label =>  'Title A-Z'
      config.add_sort_field   'title_sort desc, pub_date_sort desc', :label => 'Title Z-A'
    end

  end
end


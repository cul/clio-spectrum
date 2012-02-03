class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 
  before_filter :by_source_config

  
  def determine_active_source
    @active_source = case request.path 
    when /^\/databases/
      'Databases'
    when /^\/new_arrivals/
      'New Arrivals'
    when /^\/catalog/
      'Catalog'
    when /^\/articles/
      'Articles'
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


  def current_user


  end


  private
  def configure_search(source)

    if source == "Academic Commons"
      Blacklight.solr = RSolr::Ext.connect(:url => "http://macana.cul.columbia.edu:8080/solr-1.5/ac2_prod")
    else
      Blacklight.solr = RSolr::Ext.connect(Blacklight.solr_config)
    end
    CatalogController.configure_blacklight do |config|
      case source
      when 'Databases'

        config.default_solr_params = {
          :qt => "search",
          :per_page => 15,
          :fq  => ['{!raw f=source_facet}database']
        }

        shared_catalog_config(config)
        config.add_facet_field 'title_first_facet', :label => "Starts With"
      when 'Archives'

        config.default_solr_params = {
          :qt => "search",
          :per_page => 15,
          :fq  => ['{!raw f=source_facet}archive']
        }

        shared_catalog_config(config)
      when 'New Arrivals'

        config.default_solr_params = {
          :qt => "search",
          :per_page => 15,
          :fq  => ['{!raw f=acq_date_facet}Last 3 Months']
        }

        shared_catalog_config(config)
      when 'Catalog'

        config.default_solr_params = {
          :qt => "search",
          :per_page => 15
        }
        shared_catalog_config(config)
      when 'Quicksearch'

        config.default_solr_params = {
          :qt => "search",
          :per_page => 15
        }
        shared_catalog_config(config)
      when 'Academic Commons'
        config.default_solr_params = {
          :qt => "search",
          :per_page => 15
        }

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

    end
  end

  def by_source_config
    @active_source = determine_active_source

    configure_search(@active_source)
  end


  def shared_catalog_config(config)


    # solr field values given special treatment in the show (single result) view
    config.show.html_title = "title_display"
    config.show.heading = "title_display"
    config.show.display_type = "format"

    config.index.show_link = "title_display"
    config.index.record_display_type = ''

   
    # solr fld values given special treatment in the index (search results) view
   

    config.add_facet_field "format", :label => "Format", :limit => 3
    config.add_facet_field "pub_date_sort", :label => "Publication Date", :limit => 3, :range => true
    config.add_facet_field "author_facet", :label => "Author", :limit => 3
    config.add_facet_field "acq_date_facet", :label => "Acquisition Date", :limit => 3
    config.add_facet_field "location_facet", :label => "Location", :limit => 3
    config.add_facet_field "author_facet", :label => "Author", :limit => 3
    config.add_facet_field "language_facet", :label => "Language", :limit => 3
    config.add_facet_field "subject_topic_facet", :label => "Topic", :limit => 3
    config.add_facet_field "subject_geo_facet", :label => "Topic (Region)", :limit => 3
    config.add_facet_field "subject_era_facet", :label => "Topic (Era)", :limit => 3
    config.add_facet_field "subject_form_facet", :label => "Topic (Genre)", :limit => 3
    config.add_facet_field "lc_1letter_facet", :label => "Call Number", :limit => 26, :open => false
    config.add_facet_field "lc_2letter_facet", :label => "Refine Call Number", :limit => 26

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    
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

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
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


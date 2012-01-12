require 'blacklight/catalog'

class CatalogController < ApplicationController
  before_filter :by_source_config

  include Blacklight::Catalog

  configure_blacklight do |config|



    

    # solr field values given special treatment in the show (single result) view
    config.show.html_title = "title_display"
    config.show.heading = "title_display"
    config.show.display_type = "format"

    config.index.show_link = "title_display"
    config.index.record_display_type = ''

   
    # solr fld values given special treatment in the index (search results) view
   

    config.add_facet_field "format", :label => "Format", :limit => 20
    config.add_facet_field "author_facet", :label => "Author", :limit => 10
    config.add_facet_field "pub_date_facet", :label => "Publication Date", :limit => 10
    config.add_facet_field "acq_date_facet", :label => "Acquisition Date", :limit => 10
    config.add_facet_field "subject_topic_facet", :label => "Topic", :limit => 10
    config.add_facet_field "language_facet", :label => "Language", :limit => 10 
    config.add_facet_field "lc_1letter_facet", :label => "Call Number", :limit => 26
    config.add_facet_field "lc_2letter_facet", :label => "Refine Call Number", :limit => 26
    config.add_facet_field "subject_geo_facet", :label => "Topic (Region)", :limit => 10
    config.add_facet_field "subject_era_facet", :label => "Topic (Era)", :limit => 10
    config.add_facet_field "location_facet", :label => "Location", :limit => 10




    config.add_search_field 'all_fields', :label => 'All Fields'
    

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
    config.add_sort_field   'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
    config.add_sort_field  'acq_date_sort asc, title_sort asc', :label =>  'Acquired Earliest'
    config.add_sort_field   'acq_date_sort desc, title_sort asc', :label => 'Acquired Latest'
    config.add_sort_field   'pub_date_sort asc, title_sort asc', :label => 'Published Earliest'
    config.add_sort_field   'pub_date_sort desc, title_sort asc', :label => 'Published Latest'
    config.add_sort_field   'author_sort asc, title_sort asc', :label => 'Author A-Z'
    config.add_sort_field   'author_sort desc, title_sort asc', :label => 'Author Z-A'
    config.add_sort_field  'title_sort asc, pub_date_sort desc', :label =>  'Title A-Z'
    config.add_sort_field   'title_sort desc, pub_date_sort desc', :label => 'Title Z-A'
    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5

  end

  def index
    delete_or_assign_search_session_params

    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => "RSS for results")
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => "Atom for results")

    (@response, @document_list) = get_search_results
    @filters = params[:f] || []
    search_session[:total] = @response.total unless @response.nil?

    respond_to do |format|
      format.html { save_current_search_params; render :layout => 'quicksearch' }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end
  end


  def show
    @response, @document = get_solr_response_for_doc_id    

    respond_to do |format|
      format.html {setup_next_and_previous_documents; render :layout => "no_sidebar"}

      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons. 
        format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
      end

    end
  end

  # when a request for /catalog/BAD_SOLR_ID is made, this method is executed...
  def invalid_solr_id_error
    if Rails.env == "development"
      render # will give us the stack trace
    else
      flash[:notice] = "Sorry, you have requested a record that doesn't exist."
      redirect_to root_path
    end

  end

  private

  def by_source_config
    @active_source = determine_active_source

    CatalogController.configure_blacklight do |config|
      case @active_source
      when 'Databases'

        config.default_solr_params = {
          :qt => "search",
          :per_page => 15,
          :fq  => ['{!raw f=source_facet}database']
        }
      when 'New Arrivals'

        config.default_solr_params = {
          :qt => "search",
          :per_page => 15,
          :fq  => ['{!raw f=acq_date_facet}Last 3 Months']
        }
      when 'Catalog'

        config.default_solr_params = {
          :qt => "search",
          :per_page => 15
        }
      end 
    end
  end

end


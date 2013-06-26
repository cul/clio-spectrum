require 'blacklight/catalog'

class CatalogController < ApplicationController
  before_filter :by_source_config

  include LocalSolrHelperExtension
  include Blacklight::Catalog
  include Blacklight::Configurable
  include BlacklightUnapi::ControllerExtension



  def index
    if params['q'] == ""
      params['commit'] ||= "Search"
      params['search_field'] ||= 'all_fields'
    end

    # clean up basic search params if necessary for specific search fields.
    # [ advanced-param clean up happens in add_advanced_search_to_solr() ]
    if params['search_field'] == 'title_starts_with' && params['q']
      # left-anchored-title must be searched as quoted phrase.
      # remove any quotes the user put in, wrap in our own double-quotes
      params['q'].gsub!(/"/,'')
      params['q'] = "\"#{ params['q'] }\""
    end

    solr_search_params_logic << :add_advanced_search_to_solr
    solr_search_params_logic << :add_range_limit_params
    @query = Spectrum::Queries::Solr.new(params, self.blacklight_config)
    @show_landing_pages = (params[:q].blank? && params[:f].blank? && params[:search_field].blank?)
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => "RSS for results")
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => "Atom for results")

    # runs the blacklight_search from application_controller using the params,
    # returns the engine with embedded results
    engine = blacklight_search(params)
    @response = engine.search
    @document_list = engine.documents

    @filters = params[:f] || []

    respond_to do |format|
      format.html { save_current_search_params; render :layout => 'quicksearch' }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end


  end

  # updates the search counter (allows the show view to paginate)
  def update
    adjust_for_results_view
    session[:search][:counter] = params[:counter]
    case @active_source
    when 'databases'
      redirect_to databases_show_path
    when 'journals'
      redirect_to journals_show_path
    else

      redirect_to :action => "show"
    end
  end

  def show
    @response, @document = get_solr_response_for_doc_id
    solr_search_params_logic << :add_advanced_search_to_solr
    solr_search_params_logic << :add_range_limit_params
    @query = Spectrum::Queries::Solr.new(params, self.blacklight_config)
    add_alerts_to_documents(@document)

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

  # displays values and pagination links for a single facet field
  def facet
    @pagination = get_facet_pagination(params[:id], params)

    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end


  # NEXT-556 - send citation to more than one email address at a time
  # Override Blacklight core method, which limits to single email.
  # --
  # And now, since we've overridden this anyway, make some fixes.
  # Like, don't do Solr lookup on ID when generating form (AJAX GET),
  # only when sending emails (AJAX PUT)

  # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def email

    # We got a post - that is, a submitted form, with a "To" - send the email!
    if request.post?
      if params[:to]
        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}

        # if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
        if params[:to].match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/)
          # Don't hit Solr until we actually need to fetch field data
          @response, @documents =
            get_solr_response_for_field_values( SolrDocument.unique_key, params[:id] )
          email = RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message]}, url_gen_params)
        else
          flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
        end
      else
        flash[:error] = I18n.t('blacklight.email.errors.to.blank')
      end

      unless flash[:error]
        email.deliver
        flash[:success] = "Email sent"
        redirect_to catalog_path(params['id']) unless request.xhr?
      end
    end

    # This is supposed to catch the GET - return the HTML of the form
    unless !request.xhr? && flash[:success]
      respond_to do |format|
        format.js { render :layout => false }
        format.html
      end
    end
  end



end


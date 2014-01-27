# The CatalogController supports all catalog-based datasources:
#   Catalog, Databases, E-Journal Titles, etc.
# This was originally based on the Blacklight CatalogController.
require 'blacklight/catalog'

class CatalogController < ApplicationController
  layout "quicksearch"

  before_filter :by_source_config
  # use "prepend", or this comes AFTER included Blacklight filters,
  # (and then un-processed params are stored to session[:search])
  prepend_before_filter :preprocess_search_params
  before_filter :add_custom_solr_search_params_logic

  include Blacklight::Catalog
  include Blacklight::Configurable
  # include BlacklightUnapi::ControllerExtension

  # explicitly position this in the ancestor chain - or the engine's
  # injection will position it last (ergo, un-overridable)
  include BlacklightRangeLimit::ControllerOverride

  # load last, to override any BlackLight methods included above
  # (BlacklightRangeLimit::ControllerOverride#add_range_limit_params)
  include LocalSolrHelperExtension


  # When a catalog search is submitted, this is the
  # very first point of code that's hit
  def index
    # very useful - shows the execution order of before filters
    # logger.debug "#{   _process_action_callbacks.map(&:filter) }"

    if params['q'] == ""
      params['commit'] ||= "Search"
      params['search_field'] ||= 'all_fields'
    end

    # items-per-page ("rows" param) should be a persisent browser setting
    if params['rows'] && (params['rows'].to_i > 1)
      # Store it, if passed
      set_browser_option('catalog_per_page', params['rows'])
    else
      # Retrieve and use previous value, if not passed
      catalog_per_page = get_browser_option('catalog_per_page')
      if catalog_per_page && (catalog_per_page.to_i > 1)
        params['rows'] = catalog_per_page
      end
    end


    # this does not execute a query - it only organizes query parameters
    # conveniently for use by the view in echoing back to the user.
    @query = Spectrum::Queries::Solr.new(params, self.blacklight_config)

    @filters = params[:f] || []

    # replicates has_search_parameters?() from blacklight's catalog_helper_behavior.rb
    @show_landing_pages = (params[:q].blank? && @filters.blank? && params[:search_field].blank?)

    # Only do the following if we have search parameters 
    # (i.e., if show-landing-pages is false)
    unless @show_landing_pages

      extra_head_content <<
        view_context.auto_discovery_link_tag(
          :rss,
          url_for(params.merge(:format => 'rss')), :title => "RSS for results")
      extra_head_content <<
        view_context.auto_discovery_link_tag(
          :atom,
          url_for(params.merge(:format => 'atom')), :title => "Atom for results")

      # runs the blacklight_search from application_controller using the params,
      # returns the engine with embedded results
      engine = blacklight_search(params)
      @response = engine.search
      @document_list = engine.documents
    end


    # reach into search config to find possible source-specific service alert warning
    search_config = SEARCHES_CONFIG['sources'][@active_source]
    warning = search_config ? search_config['warning'] : nil;

    respond_to do |format|
      format.html { save_current_search_params;
                    render :locals => {:warning => warning, :response => @response},
                    :layout => 'quicksearch' }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end


  end

  # updates the search counter (allows the show view to paginate)
  def update
    adjust_for_results_view
    session[:search][:counter] = params[:counter]

    # These alternate paths all come back through catalog controller,
    # but this way we get things like the URL and @active_source correctly set.
    case @active_source
    when 'databases'
      redirect_to databases_show_path
    when 'journals'
      redirect_to journals_show_path
    when 'archives'
      redirect_to archives_show_path
    when 'new_arrivals'
      redirect_to new_arrivals_show_path
    else
      redirect_to :action => "show"
    end

  end

  def show
    @response, @document = get_solr_response_for_doc_id
    # solr_search_params_logic << :add_advanced_search_to_solr
    # solr_search_params_logic << :add_range_limit_params
    @query = Spectrum::Queries::Solr.new(params, self.blacklight_config)
    add_alerts_to_documents(@document)

    # reach into search config to find possible source-specific service alert warning
    search_config = SEARCHES_CONFIG['sources'][@active_source]
    warning = search_config ? search_config['warning'] : nil;

    respond_to do |format|
      # require 'debugger'; debugger
      format.html {
        # This Blacklight function re-runs the current query, twice,
        # just to get IDs to build next/prev links.
        # NewRelic shows this one line taking 1.5% of total processing time,
        # even though it's hitting Solr's query cache.
        setup_next_and_previous_documents;
        render :locals => { :warning => warning }, :layout => "no_sidebar"
      }

      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons.
        format.send(format_name.to_sym) {
          render :text => @document.export_as(format_name),
          :layout => false
        }
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

  # We're now emailing from within multiple classes, 
  # and this has moved to ApplicationController
  #
  # # NEXT-556 - send citation to more than one email address at a time
  # # Override Blacklight core method, which limits to single email.
  # # So far, no changes beyond removing this validation.
  #
  # # Email Action (this will render the appropriate view on GET requests and
  # # process the form and send the email on POST requests)
  # def OLD_email
  #   @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
  #   if request.post?
  #     if params[:to]
  #       url_gen_params = {
  #         :host => request.host_with_port,
  #         :protocol => request.protocol
  #       }
  #
  #       # if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
  #       if params[:to].match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/)
  #         email = RecordMailer.email_record(@documents,
  #             {:to => params[:to], :message => params[:message]},
  #             url_gen_params)
  #       else
  #         flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
  #       end
  #     else
  #       flash[:error] = I18n.t('blacklight.email.errors.to.blank')
  #     end
  #
  #     unless flash[:error]
  #       email.deliver
  #       flash[:success] = "Email sent"
  #       redirect_to catalog_path(params['id']) unless request.xhr?
  #     end
  #   end
  #
  #   unless !request.xhr? && flash[:success]
  #     respond_to do |format|
  #       format.js { render :layout => false }
  #       format.html
  #     end
  #   end
  # end

  def add_custom_solr_search_params_logic
    # this "solr_search_params_logic" is used when querying using standard
    # blacklight functions
    # queries using our Solr engine have their own config in Spectrum::Engines::Solr
    unless solr_search_params_logic.include? :add_advanced_search_to_solr
      solr_search_params_logic << :add_advanced_search_to_solr
    end
    unless solr_search_params_logic.include? :add_range_limit_params
      solr_search_params_logic << :add_range_limit_params
    end
  end

  def preprocess_search_params
    # clean up any search params if necessary, possibly only for specific search fields.

    # First Case:  left-anchored-title must be searched as quoted phrase.
    # strip any quotes the user put in, wrap in our own double-quotes

    # Second Case:  remove question marks at ends of words/phrases
    # (searches like "what is calculus?" don't expect Solr wildcard treatment )

    # Third Case:  Remove hyphen from wildcarded phrase (foo-bar*  =>  foo bar*)
    # NEXT-421 - quicksearch, catalog, and databases search: african-american* fails


    # 1) cleanup for basic searches
    if q = params['q']
      if params['search_field'] == 'title_starts_with'
        unless q =~ /^".*"$/
          # q.gsub!(/"/, '\"')    # escape any double-quotes instead?
          q.gsub!(/"/, '')    # strip any double-quotes
          q = "\"#{ q }\""
        end
      end
      q.gsub!(/\?\s+/, ' ')  # remove trailing question-marks
      q.gsub!(/\?$/, '')     # remove trailing question-marks (end of line)
      q.gsub!(/(\w+)-(\w+\*)/, '\1 \2')     # remove hyphen from wildcarded phrase
      params['q'] = q
    end

    # 2) cleanup for advanced searches
    if params['adv'] and params['adv'].kind_of?(Hash)
      params['adv'].each do |rank, advanced_param|
        if val = advanced_param['value']
          if advanced_param['field'] == "title_starts_with"
            unless val =~ /^".*"$/
              # advanced_param['value'].gsub!(/"/, '\"')    # escape any double-quotes instead?
              val.gsub!(/"/, '')    # strip any double-quotes
              val = "\"#{ val }\""
           end
          end
          val.gsub!(/\?\s+/, ' ')  # remove trailing question-marks
          val.gsub!(/\?$/, '')  # remove trailing question-marks (end of line)
          val.gsub!(/(\w+)-(\w+\*)/, '\1 \2')     # remove hyphen from wildcarded phrase
          advanced_param['value'] = val
        end
      end
    end

  end



end


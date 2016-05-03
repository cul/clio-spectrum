# The CatalogController supports all catalog-based datasources:
#   Catalog, Databases, E-Journal Titles, etc.
# (plus AcademicCommons - which uses Blacklight against a diff. Solr)
# This was originally based on the Blacklight CatalogController.

class CatalogController < ApplicationController
  layout 'quicksearch'

  before_filter :by_source_config
  # use "prepend", or this comes AFTER included Blacklight filters,
  # (and then un-processed params are stored to session[:search])
  prepend_before_filter :preprocess_search_params

  # Bring in endnote export, etc.
  include Blacklight::Marc::Catalog

  include Blacklight::Catalog
  include Blacklight::Configurable

  # load last, to override any BlackLight methods included above
  include LocalSolrHelperExtension

  # When a catalog search is submitted, this is the
  # very first point of code that's hit
  def index
    debug_timestamp('CatalogController#index() begin')

    # very useful - shows the execution order of before filters
    # logger.debug "#{   _process_action_callbacks.map(&:filter) }"


    # Moved to SearchBuilder
    # # NEXT-1043 - Better handling of extremely long queries
    # # if params['q']
    # #   # Truncate queries longer than N letters
    # #   maxLetters = 200
    # #   if params['q'].size > maxLetters
    # #     flash.now[:error] = "Your query was automatically truncated to the first #{maxLetters} letters. Letters beyond this do not help to further narrow the result set."
    # #     params['q'] = params['q'].first(maxLetters)
    # #   end
    # # 
    # #   # Truncate queries longer than N words
    # #   maxTerms = 30
    # #   terms = params['q'].split(' ')
    # #   if terms.size > maxTerms
    # #     flash.now[:error] = "Your query was automatically truncated to the first #{maxTerms} words.  Terms beyond this do not help to further narrow the result set."
    # #     params['q'] = terms[0,maxTerms].join(' ')
    # #   end
    # # end

    if params['q'] == ''
      params['commit'] ||= 'Search'
      params['search_field'] ||= 'all_fields'
    end

    # items-per-page ("rows" param) should be a persisent browser setting
    if params['rows'] && (params['rows'].to_i > 1)
      # NEXT-1199 - can't get CLIO to display more than 10 records at a time
      # 'rows' and 'per_page' are redundant.
      # if we have a valid 'rows', ignore 'per_page'
      params.delete('per_page')
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
    @query = Spectrum::Queries::Solr.new(params, blacklight_config)

    @filters = params[:f] || []

    # replicates has_search_parameters?() from blacklight's catalog_helper_behavior.rb
    @show_landing_pages = (params[:q].blank? && @filters.blank? && params[:search_field].blank?)

    # Only do the following if we have search parameters
    # (i.e., if show-landing-pages is false)
    unless @show_landing_pages

      # runs ApplicationController.blacklight_search() using the params,
      # returns the engine with embedded results
      debug_timestamp('CatalogController#index() before blacklight_search()')

      search_engine = blacklight_search(params)
      debug_timestamp('CatalogController#index() after blacklight_search()')

      # These will only be set if the search was successful
      @response = search_engine.search
      @document_list = search_engine.documents
      # If the search was not successful, there may be errors
      @errors = search_engine.errors
      debug_timestamp('CatalogController#index() end - implicit render to follow')
    end

    # reach into search config to find possible source-specific service alert warning
    search_config = SEARCHES_CONFIG['sources'][@active_source]
    warning = search_config ? search_config['warning'] : nil
# raise
    respond_to do |format|
      format.html do render locals: { warning: warning, response: @response },
                            layout: 'quicksearch' end
      format.rss  { render layout: false }
      format.atom { render layout: false }
    end
  end


  # updates the search counter (allows the show view to paginate)
  def track
    session[:search] = {} unless session[:search].is_a?(Hash)
    session[:search]['counter'] = params[:counter]

    # Blacklight wants this....
    # session[:search]['per_page'] = params[:per_page]
    # But our per-page/rows value is persisted here:
    session[:search]['per_page'] = get_browser_option('catalog_per_page')

    path = case @active_source
    when 'databases'
       databases_show_path
    when 'journals'
       journals_show_path
    when 'archives'
       archives_show_path
    when 'new_arrivals'
       new_arrivals_show_path
    else
      { action: 'show' }
    end

    # If there's a 'redirect' param (the original 'href' of the clicked link), 
    # respect that instead.
    if params[:redirect] and (params[:redirect].starts_with?("/") or params[:redirect] =~ URI::regexp)
      path = URI.parse(params[:redirect]).path
    end

    redirect_to path, :status => 303
  end


  def librarian_view_track
    session[:search]['counter'] = params[:counter]
    redirect_to action: 'librarian_view'
  end

  def show
    @response, @document = fetch params[:id]

    # In support of "nearby" / "virtual shelf browse", remember this bib
    # as our focus bib.
    session[:browse] = {} unless session[:browse].is_a?(Hash)
    session[:browse]['bib'] = @document.id
    # Need the Call Number/Shelfkey too, extract from 'item_display'
    # (If bib has multiple call-nums, default to first.)
    active_item_display = Array(@document['item_display']).first
    session[:browse]['call_number'] = get_call_number(active_item_display)
    session[:browse]['shelfkey'] = get_shelfkey(active_item_display)


    # this does not execute a query - it only organizes query parameters
    # conveniently for use by the view in echoing back to the user.
    @query = Spectrum::Queries::Solr.new(params, blacklight_config)

    add_alerts_to_documents(@document)

    # reach into search config to find possible source-specific service alert warning
    search_config = SEARCHES_CONFIG['sources'][@active_source]
    warning = search_config ? search_config['warning'] : nil

    respond_to do |format|
      # require 'debugger'; debugger
      format.html do
        # This Blacklight function re-runs the current query, twice,
        # just to get IDs to build next/prev links.
        # NewRelic shows this one line taking 1.5% of total processing time,
        # even though it's hitting Solr's query cache.
        # raise
        setup_next_and_previous_documents
        render locals: { warning: warning }, layout: 'no_sidebar'
      end

      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons.
        format.send(format_name.to_sym) do
          render text: @document.export_as(format_name),
                 layout: false
        end
      end

    end
  end

  # when a request for /catalog/BAD_DOCUMENT_ID is made, this method is executed...
  def invalid_document_id_error
    flash[:notice] = t('blacklight.search.errors.invalid_solr_id')
    redirect_to root_path
  end


  # Override Blacklight::Catalog.facet()
  #   [ Why do we need to ??? ]
  def facet
    @facet = blacklight_config.facet_fields[params[:id]]

    # Allow callers to pass in extra params, that won't be sanitized-out by
    # the processing that 'params' undergoes
    extra_params = params[:extra_params] || {}

    @response = get_facet_field_response(@facet.key, params, extra_params)
    @display_facet = @response.aggregations[@facet.key]

    @pagination = facet_paginator(@facet, @display_facet)

    respond_to do |format|
      # Draw the facet selector for users who have javascript disabled:
      format.html
      format.json { render json: render_facet_list_as_json }

      # Draw the partial for the "more" facet modal window:
      format.js { render :layout => false }
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
    if params['adv'] && params['adv'].kind_of?(Hash)
      params['adv'].each do |rank, advanced_param|
        if val = advanced_param['value']
          if advanced_param['field'] == 'title_starts_with'
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

  # Override Blacklight's definition, to assign custom layout
  def librarian_view
    @response, @document = fetch params[:id]
    respond_to do |format|
      format.html do
        # This Blacklight function re-runs the current query, twice,
        # just to get IDs to build next/prev links.
        # NewRelic shows this one line taking 1.5% of total processing time,
        # even though it's hitting Solr's query cache.
        setup_next_and_previous_documents
        # raise
        render layout: 'no_sidebar'
      end
      format.js { render layout: false }
    end
  end

  # Called via AJAX to build the hathi holdings section
  # on the item-detail page.
  def hathi_holdings
    @response, @document = fetch params[:id]

    respond_to do |format|
      format.html { render layout: false }
    end
  end

end

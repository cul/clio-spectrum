# The CatalogController supports all catalog-based datasources:
#   Catalog, Databases, E-Journal Titles, etc.
# (plus AcademicCommons - which uses Blacklight against a diff. Solr)
# This was originally based on the Blacklight CatalogController.

class CatalogController < ApplicationController
  # include ActionController::Live

  attr_accessor :source

  include BlacklightRangeLimit::ControllerOverride
  layout 'quicksearch'

  # use "prepend", or this comes AFTER included Blacklight filters,
  # (and then un-processed params are stored to session[:search])
  prepend_before_action :preprocess_search_params

  # Bring in endnote export, etc.
  include Blacklight::Marc::Catalog

  # done in application_controller
  # include Blacklight::Catalog
  # include Blacklight::Configurable

  # load last, to override any BlackLight methods included above
  include LocalSolrHelperExtension

  # When a catalog search is submitted, this is the
  # very first point of code that's hit
  def index
    @source = active_source
    params['source'] = @source
    debug_timestamp('CatalogController#index() begin')

    # this will show the execution order of before filters:
    #   logger.debug "#{   _process_action_callbacks.map(&:filter) }"

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

      search_engine = blacklight_search(params.to_unsafe_h)
      debug_timestamp('CatalogController#index() after blacklight_search()')

      # These will only be set if the search was successful
      @response = search_engine.search
      @document_list = search_engine.documents
      # If the search was not successful, there may be errors
      @errors = search_engine.errors
      debug_timestamp('CatalogController#index() end - implicit render to follow')
    end

    # reach into search config to find possible source-specific service alert warning
    search_config = DATASOURCES_CONFIG['datasources'][@source]
    warning = search_config ? search_config['warning'] : nil
    # raise
    respond_to do |format|
      format.html do
        render locals: { warning: warning, response: @response },
               layout: 'quicksearch'
      end
      # format.csv do
      #   # render locals: {response: @response, errors: @errors},
      #   #        layout: false,
      #   #        filename: 'foo'
      #   send_data results_as_csv(@response), filename: csv_filename()
      # end
      format.rss  { render layout: false }
      format.atom { render layout: false }
      # format.xls  {
      #   render locals: {response: @response}, layout: false
      #   response.headers['Content-Disposition'] = "attachment; filename=foo.xls"
      # }
    end
  end

  # updates the search counter (allows the show view to paginate)
  def track
    # session[:search] = {} unless session[:search].is_a?(Hash)
    # session[:search]['counter'] = params[:counter]
    #
    # # Blacklight wants this....
    # # session[:search]['per_page'] = params[:per_page]
    # # But our per-page/rows value is persisted here:
    # session[:search]['per_page'] = get_browser_option('catalog_per_page')

    search_session['counter'] = params[:counter]
    search_session['id'] = params[:search_id]
    search_session['per_page'] = get_browser_option('catalog_per_page')

    path = case active_source
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
    if params[:redirect] && (params[:redirect].starts_with?('/') || params[:redirect] =~ URI.regexp)
      path = URI.parse(params[:redirect]).path
    end

    redirect_to path, status: 303
  end

  def librarian_view_track
    session[:search]['counter'] = params[:counter]
    redirect_to action: 'librarian_view'
  end

  def show
    @response, @document = fetch params[:id]

    # If the Solr document contains holdings fields,
    # - fetch real-time circulation status
    # - build Holdings data structure

    if @document.has_marc_holdings?
      circ_status = nil
      # Don't check Voyager circ status for non-Columbia records
      if @document.has_circ_status?
        circ_status = BackendController.circ_status(params[:id])
      end

      # TODO:  What about bound-withs?  The blind barcode is usually that of
      # an offsite item, which would have a SCSB status.
      if @document.has_offsite_holdings?
        # Lookup SCSB availability hash (simplification of full status)
        scsb_status = BackendController.scsb_availabilities(params[:id])
        # Simple hash to map barcode to "Available"/"Unavailable"
        # {
        #   "CU18799175"  =>  "Available"
        # }
      end

      @collection = Voyager::Holdings::Collection.new(@document, circ_status, scsb_status)

      @holdings = @collection.to_holdings

    else
      # Pegasus (Law) documents have no MARC holdings.
      # Everything else is supposed to.
      unless @document.in_pegasus?
        Rails.logger.error "Document #{@document.id} has no MARC holdings!"
      end
    end

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
    search_config = DATASOURCES_CONFIG['datasources'][active_source]
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

      format.json { render json: { response: { document: @document } } }

      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do |format_name|
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons.
        format.send(format_name.to_sym) do
          render plain: @document.export_as(format_name),
                 layout: false
        end
      end
    end
  end

  # when a request for /catalog/BAD_DOCUMENT_ID is made, this method is executed...
  def invalid_document_id_error
    flash.now[:notice] = t('blacklight.search.errors.invalid_solr_id')
    @show_landing_pages = true

    # For .xml, .endnote, etc., don't return a webpage
    if params['format']
      render body: nil, status: :not_found
    else
      render 'spectrum/search', status: :not_found
    end
  end

  # Override Blacklight::Catalog.facet()
  #   [ Why do we need to ??? ]
  def facet
    # raise
    @facet = blacklight_config.facet_fields[params[:id]]
    return render json: nil, status: :bad_request unless @facet

    # Allow callers to pass in extra params, that won't be sanitized-out by
    # the processing that 'params' undergoes
    extra_params = params[:extra_params] || {}

    @response = get_facet_field_response(@facet.key, params, extra_params)
    @display_facet = @response.aggregations[@facet.key]

    @pagination = facet_paginator(@facet, @display_facet)

    # 2/23/2017 - turned off after two weeks of data collection (NEXT-908)
    # # 2/7/2017 - get some info on see-more sizes, hopefully to be
    # # turned off pretty soon.  Hardcode test to current limit, 500)
    # limit = (@display_facet.items.size == 501) ? ' - HIT LIMIT' : ''
    # Rails.logger.warn "FACET-SEE-MORE name: #{@display_facet.name} count: #{@display_facet.items.size}#{limit}"

    respond_to do |format|
      # Draw the facet selector for users who have javascript disabled:
      format.html
      format.json { render json: render_facet_list_as_json }

      # Draw the partial for the "more" facet modal window:
      format.js { render layout: false }
    end
  end

  def preprocess_search_params
    # clean up any search params if necessary, possibly only for specific search fields.

    # left-anchored-title must be searched as quoted phrase.
    # strip any quotes the user put in, wrap in our own double-quotes

    # remove question marks at ends of words/phrases
    # (searches like "what is calculus?" don't expect Solr wildcard treatment )

    # Remove hyphen from wildcarded phrase (foo-bar*  =>  foo bar*)
    # NEXT-421 - quicksearch, catalog, and databases search: african-american* fails

    # cleanup for basic searches
    if q = params['q']
      if params['search_field'] == 'title_starts_with'
        unless q =~ /^".*"$/
          # q.gsub!(/"/, '\"')    # escape any double-quotes instead?
          q.delete!('"') # strip any double-quotes
          q = "\"#{q}\""
        end
      end
      q.gsub!(/(\w+)-(\w+\*)/, '\1 \2') # remove hyphen from wildcarded phrase
      params['q'] = q
    end

    # cleanup for advanced searches
    if params['adv'] && params['adv'].is_a?(Hash)
      params['adv'].each do |_rank, advanced_param|
        next unless val = advanced_param['value']
        if advanced_param['field'] == 'title_starts_with'
          unless val =~ /^".*"$/
            # advanced_param['value'].gsub!(/"/, '\"')    # escape any double-quotes instead?
            val.delete!('"') # strip any double-quotes
            val = "\"#{val}\""
         end
        end
        val.gsub!(/\?\s+/, ' ') # remove trailing question-marks
        val.gsub!(/\?$/, '') # remove trailing question-marks (end of line)
        val.gsub!(/(\w+)-(\w+\*)/, '\1 \2') # remove hyphen from wildcarded phrase
        advanced_param['value'] = val
      end
    end
    
    # Some browsers interact with facet input elements oddly, 
    # injecting positional keys:  'alpha' becomes ['0' => 'alpha']
    # We need to undo this.
    if params['f']
      clean_f = {}
      # loop over each facet key (author, language, etc.)
      params['f'].each_pair do |facet_key, facet_value|
        # the normal case - pass-through value as-is
        if facet_value.is_a?(Array)
          clean_f[facet_key] = facet_value
        elsif facet_value.class == ActionController::Parameters &&         
              facet_value.keys.count == 1 &&
              facet_value.values.count == 1 &&
              facet_value.keys.first.match(/^\d$/)
          # Found a postional key!  Use the value of the value
          clean_f[facet_key] = facet_value.values
        end
      end
      params['f'] = clean_f
    end
    
    # If user mixes up min and max years for pub-date search, flip them
    if params[:range] && params[:range][:pub_date_sort]
      if (range_begin = params[:range][:pub_date_sort][:begin]) &&
         (range_end   = params[:range][:pub_date_sort][:end])
         if range_begin.to_i > range_end.to_i
           params[:range][:pub_date_sort][:begin] = range_end
           params[:range][:pub_date_sort][:end]   = range_begin
         end
      end
    end

  end

  # Override Blacklight's definition, to assign custom layout
  def librarian_view
    @response, @document = fetch params[:id]

    # Staff want to see Collection Group Designation in the librarian view
    @barcode2cgd = {}
    if @document.has_offsite_holdings?
      # Fetch full array of status hashes
      scsb_status = BackendController.scsb_status(params[:id])
      scsb_status.each do |item|
        @barcode2cgd[item['itemBarcode']] = item['collectionGroupDesignation']
      end
      # Simple hash to map barcode to "Open"/"Shared"/"Closed"
      # {
      #   "CU18799175"  =>  "Available"
      # }
    end

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

  # Override BL6 Blacklight::Catalog concern
  def validate_sms_params
    # raise
    if params[:to].blank?
      flash[:error] = I18n.t('blacklight.sms.errors.to.blank')
    elsif params[:carrier].blank?
      flash[:error] = I18n.t('blacklight.sms.errors.carrier.blank')
    elsif params[:to].gsub(/[^\d]/, '').length != 10
      flash[:error] = I18n.t('blacklight.sms.errors.to.invalid', to: params[:to])
    elsif !sms_mappings.values.include?(params[:carrier])
      flash[:error] = I18n.t('blacklight.sms.errors.carrier.invalid')
    elsif current_user.blank? && !@user_characteristics[:on_campus] && !verify_recaptcha
      flash[:error] = 'reCAPTCHA verify error'
    end

    flash[:error].blank?
  end

  # Authenticated CUL Staff can download search results as XLS
  def xls_form()  
    # build a form to collect details for the XLS format.
    # pass through all query params as hidden form elements.

    # respond_to do |format|
    #   format.js { render layout: false }
    #   format.html
    # end
  end

  # "XML Spreadsheet 2003"
  def xls_download()
    params['format'] = 'xls'
    params['source'] = active_source
    search_engine = blacklight_search(params.to_unsafe_h)
    @response = search_engine.search

    respond_to do |format|
      format.xls do
        # render locals: {response: @response}, layout: false
        # response.headers['Content-Disposition'] = "attachment; filename=foo.xlsx"
        headers["Content-Type"] = "application/vnd.ms-excel"
        headers["Content-Disposition"] =
           %(attachment; filename="foo.xml")
        self.response_body = build_xls_enumerator()
      end
    end
  end

# Example from:
#   https://thoughtbot.com/blog/modeling-a-paginated-api-as-a-lazy-stream
# def fetch_paginated_data(path)
#   Enumerator.new do |yielder|
#     page = 1
# 
#     loop do
#       results = fetch_data("#{path}?page=#{page}")
# 
#       if results.success?
#         results.map { |item| yielder << item }
#         page += 1
#       else
#         raise StopIteration
#       end
#     end
#   end.lazy
# end

  def build_xls_enumerator
    Enumerator.new do |yielder|
      # initialize params for Solr query
      params['page'] = '1'
      params['rows'] = '10'

      yielder << x_header

      loop do
        # fetch one page of records from Solr
        Rails.logger.debug "==== page=#{params['page']}"
        search_engine = blacklight_search(params.to_unsafe_h)
        response = search_engine.search
        document_list = search_engine.documents

        # We've encountered some kind of problem
        raise StopIteration if search_engine.errors

        # We've read all docs for this query
        if response.total == 0 || document_list.size == 0
          yielder << xls_footer
          raise StopIteration
        end
        # raise StopIteration if response.total == 0
        # raise StopIteration if document_list.size == 0

        # convert SolrDocument objects to XSL, feed to enumerator
        search_engine.documents.each do |solr_doc|
          yielder << solr_doc.to_xls
        end
        
        # advance pagination
        params['page'] = (params['page'].to_i + 1).to_s
        # params['page'] += 1
        
      end

    end
  end

  def xls_header
    header = <<-FOO
<?xml version="1.0" encoding="UTF-8"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" xmlns:html="https://www.w3.org/TR/html401/">
<Worksheet ss:Name="CLIO XLS Download">
<Table>
<Column ss:Index="1" ss:AutoFitWidth="0" ss:Width="110"/>
FOO
    return header
  end
  
  def xls_footer
    footer = <<-FOO
</Table>
</Worksheet>
</Workbook>
    FOO
    return footer
  end
      
  # def results_as_csv(response)
  #   rows = []
  #   
  #   # add header row
  #   rows <<  CSV.generate_line(SolrDocument.csv_headers)
  #   
  #   # row or rows for each document in the result set
  #   @response.documents.each do |document|
  #     # each document might become multiple rows (per holding, per item)
  #     # Whatever we get back, append to our growing array of lines of CSV output
  #     rows += document.to_csv
  #   end
  # 
  #   # final join of all individual string rows into a single very long multi-line string 
  #   return rows.join
  # end
  
  # Generate an appropriate filename for each downloaded result set.
  # Something generated based on query conditions would be complex, and collide.
  # Instead, just do date/timestamp
  def download_filename(suffix = 'txt')
    now = Time.now.strftime("%Y-%m-%d_%H%M")
    filename = "CLIO_#{now}.#{suffix}"
    return filename
  end

  # Use xlsxtream for streaming download of XLSX (not Spreadsheet XML, as in 'xls_download')
  def xlsx_download()

    # headers for streaming suggested by:
    #   https://coderwall.com/p/kad56a/streaming-large-data-responses-with-rails
    # and
    #   https://github.com/felixbuenemann/xlsxtream/issues/14
    response.headers.delete("Content-Length") # See one line above
    response.headers['X-Accel-Buffering'] = 'no' # Stop NGINX from buffering
    response.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    response.headers['Content-Disposition'] = "attachment; filename=#{download_filename('xlsx')}"                 
    response.headers['Cache-Control'] = 'no-cache'                                                                

    # fails during localhost testing.
    # response.headers["Transfer-Encoding"] = "chunked" # Chunked response header

    # initialize params for Solr query
    params['page'] = '1'

    params['rows'] = '1000'
    # Blacklight's config is set to 100-record max rows.
    # We need to override this for reporting - but doing
    # this here doesn't work.
    # blacklight_config.max_per_page = 1000

    params['source'] = active_source
    search_engine = blacklight_search(params.to_unsafe_h)
    @response = search_engine.search

    stream = response.stream
    stream.define_singleton_method(:<<) { |value| write(value) }
    
    begin
      xlsx = Xlsxtream::Workbook.new(stream)
      xlsx.write_worksheet 'Sheet1' do |sheet|

        # testing...
        # 3.times do |i|
        #   sheet << ["asdf", "aaa", "aligator"]
        # end

        total = 0
        hits = 999
        while hits > 0 && total < 10_000
          search_engine = blacklight_search(params.to_unsafe_h)
          hits = search_engine.documents.count
          total += hits

          search_engine.documents.each do |solr_doc|
            # 1 or more rows, depending on level (bib, holding, item)
            doc_rows = solr_doc.to_xlsx(params['level'])
            doc_rows.each { |row| sheet << row }
            # # sheet << solr_doc.to_xlsx(params['level'])
          end

          # increment page
          params['page'] = (params['page'].to_i + 1).to_s
        end

      end
      xlsx.close
    ensure
      stream.close
    end

    # respond_to do |format|
    #   format.xls do
    #     # render locals: {response: @response}, layout: false
    #     # response.headers['Content-Disposition'] = "attachment; filename=foo.xlsx"
    #     headers["Content-Type"] = "application/xls"
    #     headers["Content-Disposition"] =
    #        %(attachment; filename="foo.xls")
    #     self.response_body = build_xls_enumerator()
    #   end
    # end


  end

end

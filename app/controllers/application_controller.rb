## Top level controller defining application-wide behaviors,
# filters, authentication, methods used throughout multiple
# classes, etc.
require 'mail'

# # UNIX-5942 - work around spotty CUIT DNS
# require 'resolv-hosts-dynamic'
# require 'resolv-replace'

class ApplicationController < ActionController::Base
  helper_method :set_browser_option, :get_browser_option, :debug_timestamp, :active_source

  include Devise::Controllers::Helpers
  devise_group :user, contains: [:user]

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::Catalog
  include Blacklight::Configurable

  include BrowseSupport
  include PreferenceSupport

  # Please be sure to implement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.
  check_authorization
  skip_authorization_check

  # Set headers to prevent all caching in authenticated sessions,
  # so that people can't 'back' in the browser to see possibly secret stuff.
  before_action :set_cache_headers

  before_action :apply_random_q
  # before_action :trigger_async_mode
  before_action :trigger_debug_mode
  # before_action :by_source_config
  before_action :log_additional_data
  before_action :set_user_characteristics
  before_action :condense_advanced_search_params

  # https://github.com/airblade/paper_trail/#4a-finding-out-who-was-responsible-for-a-change
  before_action :set_paper_trail_whodunnit

  # Access to the current ApplicationController instance from anywhere
  # https://stackoverflow.com/a/33774123/1343906
  cattr_accessor :current
  before_action { ApplicationController.current = self }
  after_action  { ApplicationController.current = nil  }

  # NEXT-537 - logging in should not redirect you to the root path
  # from the Devise how-to docs...
  # https://github.com/plataformatec/devise/wiki/
  # How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update
  before_action :store_location

  # Polling for logged-in-status shouldn't update the devise last-activity tracker
  prepend_before_action :skip_timeout, only: [:render_session_status, :render_session_timeout]
  def skip_timeout
    request.env['devise.skip_trackable'] = true
  end

  # As of 2/19/2019, CUIT seems to have resolved this problem.
  # # UNIX-5942 - work around spotty CUIT DNS
  # prepend_before_action :cache_dns_lookups

  rescue_from CanCan::AccessDenied do |exception|
    # note - access denied gives a 302 redirect, not 403 forbidden.
    # see https://github.com/ryanb/cancan/wiki/exception-handling
    redirect_to root_url, alert: exception.message
  end

  rescue_from ActionView::MissingTemplate do |exception|
    if request.format == 'html'
      redirect_to root_url, alert: exception.message
    else
      Rails.logger.warn "request.format = #{request.format}"
      Rails.logger.warn exception.to_s
      render body: nil
    end
  end

  def apply_random_q
    if params[:random_q]
      start = Time.now
      chosen_line = nil
      line_to_pick = rand(11_917)
      input_file = File.join(Rails.root.to_s, 'config', 'opac_searches_sorted.txt')
      File.foreach(input_file).each_with_index do |line, number|
        chosen_line = line if number == line_to_pick
      end
      params['q'] = chosen_line
      # params['s.q'] = chosen_line
    end
  end

  def condense_advanced_search_params
    advanced_search_params = params['adv'] || {}
    advanced_search_params = {} if advanced_search_params == '{}'
    new_hash = {}
    counter = 1
    advanced_search_params.each_pair do |_adv_field_number, attrs|
      if attrs && !attrs['field'].to_s.empty? && !attrs['value'].to_s.empty?
        new_hash[counter.to_s] = attrs
        counter += 1
      end
    end
    params['adv'] = new_hash
  end

  def set_user_characteristics
    # remote_ip gives back whatever's in X-Forwarded-For, which can
    # be manipulated by the client.  use remote_addr instead.
    # this will have to be revisited if/when clio lives behind a proxy.
    client_ip = request.remote_addr
    is_on_campus = User.on_campus?(client_ip)
    @user_characteristics =
      {
        ip: client_ip,
        on_campus: is_on_campus
      }
    @debug_entries[:user_characteristics] = @user_characteristics
  end

  # AJAX handler for browser-option setting/getting
  def set_browser_option_handler
    unless params.key?('name') && params.key?('value')
      render(json: nil, status: :bad_request) && return
    end

    set_browser_option(params['name'], params['value'])
    render json: nil, status: :ok
  end

  # Rails method for browser-option setting/getting
  def set_browser_option(name, value)
    _clio_browser_options = YAML.load(cookies[:_clio_browser_options] || '{}')
    _clio_browser_options = {} unless _clio_browser_options.is_a?(Hash)
    _clio_browser_options[name] = value
    cookies[:_clio_browser_options] = { value: _clio_browser_options.to_yaml,
                                        expires: 1.year.from_now }
  end

  # AJAX handler for browser-option setting/getting
  def get_browser_option_handler
    if params.key?('value') || !params.key?('name')
      render(json: nil, status: :bad_request) && return
    end

    if value = get_browser_option(params['name'])
      render json: value, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  # Rails method for browser-option setting/getting
  def get_browser_option(name)
    _clio_browser_options = YAML.load(cookies[:_clio_browser_options] || '{}')
    _clio_browser_options.is_a?(Hash) ? _clio_browser_options[name] : nil
  end

  # AJAX handler for persistence of selected-items
  def selected_items_handler
    render(json: nil, status: :bad_request) && return unless params.key?('verb')

    verb = params['verb']
    id_param = params['id_param']

    selected_item_list = Array(session[:selected_items]).flatten

    case verb
    when 'add'
      return render json: nil, status: :bad_request unless id_param
      selected_item_list.push(id_param)
    when 'remove'
      return render json: nil, status: :bad_request unless id_param
      selected_item_list.delete(id_param)
    when 'clear'
      selected_item_list = []
    when 'reset'
      # return render json: nil, status: :bad_request unless id_param
      # Fail silently for this one - it's run on every page load
      # Or... maybe reset to a null list if id_param isn't given?
      id_param = [] unless id_param
      selected_item_list = id_param if id_param
    else
      render(json: nil, status: :bad_request) && return
    end

    session[:selected_items] = selected_item_list

    render json: nil, status: :ok
  end

  # Called from SpectrumController.get_results()
  # and from CatalogController.index()
  def blacklight_search(sent_options = {})
    # raise
    # Rails.logger.debug "ApplicationController#blacklight_configght_search(sent_options=#{sent_options.inspect})"
    options = sent_options.deep_clone
    # options['source'] = active_source unless options['source']
    options['debug_mode'] = @debug_mode
    options['current_user'] = current_user

    # this new() actually runs the search.
    # [ the Solr engine call perform_search() within it's initialize() ]
    debug_timestamp('blacklight_search() calling Solr.new()')
    # puts "QQQQ   blacklight_search(#{options['source']})"
    search_engine = Spectrum::SearchEngines::Solr.new(options)
    # puts "QQQQ   done(#{options['source']})"
    debug_timestamp('blacklight_search() Solr.new() complete.')

    if search_engine.successful?
      @response = search_engine.search
      @results = search_engine.documents
      # Currently, item-alerts only show within the Databases data source. (Why?)
      if active_source.present? && active_source == 'databases'
        add_alerts_to_documents(@results)
      end
    end

    @debug_entries ||= {}

    # our search engine classes don't inherit from ApplicationController.
    # they may set their own @debug_entries instance variables, which we
    # here need to merge in with the controller-level instance variable.
    @debug_entries = @debug_entries.recursive_merge(search_engine.debug_entries)

    search_engine
  end

  def trigger_debug_mode
    params_debug_mode = params['debug_mode']

    if params_debug_mode == 'on'
      @debug_mode = true
    elsif params_debug_mode == 'off'
      @debug_mode = false
    else
      @debug_mode ||= session['debug_mode'] || false
    end

    params.delete('debug_mode')

    @debug_mode = false unless current_user

    # 11/2017 - CUD wants to see debug details
    @debug_mode = true if current_user && current_user.has_role?('site', 'pilot')

    session['debug_mode'] = @debug_mode

    @current_user = current_user
    default_debug
  end

  def default_debug
    @debug_start_time = Time.now
    @debug_entries = Hash.arbitrary_depth
    @debug_entries['params'] = params

    # Rails 4?  session.inspect now dumps full object internals,
    # instead of just stored keys/values.  Convert to hash first.
    @debug_entries['session'] = session.to_hash

    # ENV is environment variables, but not the HTTP-related env variables
    # @debug_entries['environment'] = ENV
    @debug_entries['request.referer'] = request.referer
    @debug_entries['timestamps'] = []
    debug_timestamp('setup')
  end

  def debug_timestamp(label = 'timestamp')
    elapsed = (Time.now - @debug_start_time) * 1000
    @debug_entries['timestamps'] << { label => "#{elapsed.round(0)} ms" }
  end

  def active_source
    # Figure out the active source, then stash it into
    # thread storage for access in non-CLIO-application contexts
    Thread.current[:active_source] = determine_active_source
  end

  def determine_active_source
    # Try to find the datasource,
    # first in the params,
    # second in the path
    source = if params.key? 'datasource'
               params['datasource']
             else
               request.path.to_s.gsub(/^\//, '').gsub(/\/.*/, '')
    end

    # Remap as necessary...
    # shelf-browse is part of the catalog datasource
    source = 'catalog' if source == 'browse'

    # If what we found is a real source, use it.
    # Otherwise, fall back to quicksearch as a default.
    if DATASOURCES_CONFIG['datasources'].key?(source)
      # Some pseudo-sources (e.g., 'catalog_dissertations') are just
      # customizations of their super-sources.  Check for that.
      if DATASOURCES_CONFIG['datasources'][source].key?('supersource')
        return DATASOURCES_CONFIG['datasources'][source]['supersource']
      else
        return source
      end
    end

    'quicksearch'
  end

  def repository_class
    Rails.logger.debug 'ApplicationController#repository_class'
    Spectrum::SolrRepository
  end

  def blacklight_config(source = active_source)
    # Rails.logger.debug "ApplicationController#blacklight_config"
    @blacklight_configs ||= {}
    @blacklight_configs[source] ||= Spectrum::SearchEngines::Solr.generate_config(source)
  end

  def catch_404s
    unrouted_uri = request.fullpath
    alert = "remote ip: #{request.remote_ip}   Invalid URL: #{unrouted_uri}"
    logger.warn alert
    redirect_to root_path, alert: alert
  end

  # 7/13 - we'll need to send email from multiple datasources,
  # so move this core function to application controller.
  # (remove catalog-specific, solr-specific code???)

  # NEXT-556 - send citation to more than one email address at a time
  # Override Blacklight core method, which limits to single email.
  # --
  # And now, since we've overridden this anyway, make some fixes.
  # Like, don't do Solr lookup on ID when generating form (AJAX GET),
  # only when sending emails (AJAX PUT)

  # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def email
    mail_to = params[:to]
    # allow user to enter email address and name to include in email (NEXT-910)
    if params[:reply_to]
      reply_to = Mail::Address.new params[:reply_to]
      reply_to.display_name = params[:name]
    end
    # We got a post - that is, a submitted form, with a "To" - send the email!
    if request.post? && (current_user.present? || @user_characteristics[:on_campus] || verify_recaptcha)
      if mail_to
        url_gen_params = { host: request.host_with_port, protocol: request.protocol }

        if mail_to =~ /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/
          # IDs may be Catalog Bib keys or Summon BookMarks...
          @documents = ids_to_documents(params[:id])
          if @documents.nil? || @documents.empty?
            flash[:error] = I18n.t('blacklight.email.errors.invalid')
          else
            message_text = params[:message]
            email = RecordMailer.email_record(@documents, { to: mail_to, reply_to: reply_to.format, message: message_text }, url_gen_params, active_source)
          end
        else
          flash[:error] = I18n.t('blacklight.email.errors.to.invalid', to: mail_to)
        end
      else
        flash[:error] = I18n.t('blacklight.email.errors.to.blank')
      end

      unless params['id']
        flash[:error] = I18n.t('blacklight.email.errors.invalid')
      end

      unless flash[:error]
        email.deliver_now
        flash[:success] = 'Email sent'
        redirect_to solr_document_path(params['id']) unless request.xhr?
      end
    else
      # pre-fill email form with user's email and name (NEXT-810)
      if current_user
        reply_to = Mail::Address.new current_user.email
        reply_to.display_name = "#{current_user.first_name} #{current_user.last_name}"
        @display_name = reply_to.display_name if reply_to
        @reply_to = reply_to.address if reply_to
      end
    end

    # This is supposed to catch the GET - return the HTML of the form
    unless !request.xhr? && flash[:success]
      respond_to do |format|
        format.js { render layout: false }
        format.html
      end
    end
  end

  def ids_to_documents(id_array = [])
    # Array-ize single id inputs: '123' --> [ '123' ]
    id_array = Array.wrap(id_array)
    return [] if id_array.empty?

    # First, split into per-source lists,
    # (depend on Summon BookMarks to be very long...)
    catalog_ids = []
    article_bookmarks = []
    Array.wrap(id_array).each do |item_id|
      if item_id.length > 50
        article_bookmarks.push item_id
      else
        catalog_ids.push item_id
      end
    end

    # Next, lookup each list in it's own way,
    # to get hashes of key-to-document
    catalog_docs_hash = get_catalog_docs_for_ids(catalog_ids) || {}
    article_docs_hash = get_summon_docs_for_bookmarks(article_bookmarks) || {}

    # Finally, merge the hashes, preserving doc id order,
    # and return the array of documents
    document_array = []
    Array.wrap(id_array).each do |item_id|
      if catalog_docs_hash.key? item_id
        document_array.push catalog_docs_hash[item_id]
      elsif article_docs_hash.key? item_id
        document_array.push article_docs_hash[item_id]
      end
    end

    document_array.compact

  end

  # passed an array of catalog document ids,
  # return a hash of { id => Catalog-Document-Object }
  def get_catalog_docs_for_ids(id_array = [])
    return {} unless id_array.is_a?(Array) || id_array.empty?

    docs = {}

    # NEXT-1067 - Saved Lists broken for very large lists, query by slice
    id_array.each_slice(100) do |slice|
      extra_solr_params = { rows: slice.size }
      response, slice_document_list = fetch(slice, extra_solr_params)
      slice_document_list.each do |doc|
        docs[doc.id] = doc
      end
    end

    docs

  end

  # passed an array of bookmarks,
  # return a hash of { bookmark => Summon-Document-Object }
  def get_summon_docs_for_bookmarks(bookmark_array = [])
    return {} unless bookmark_array.is_a?(Array) || bookmark_array.empty?

    config = APP_CONFIG['summon']
    config.symbolize_keys!
    # URL can be in app_config, or fill in with default value
    config[:url] ||= 'http://api.summon.serialssolutions.com/2.0.0'

    docs = {}
    @errors = nil

    service = ::Summon::Service.new(config)
    bookmark_array.each do |bookmark|
      Rails.logger.debug "bookmark #{bookmark}..."
      params = { 's.bookMark' => bookmark }
      search = nil

      begin
        search = service.search(params)
      rescue Summon::Transport::RequestError => ex
        Rails.logger.warn "Summon::Transport::RequestError - #{ex}"
        next
      rescue => ex
        Rails.logger.error "[Spectrum][Summon] error: #{e.message}"
        @errors = ex.message
      end

      next unless search && search.documents.present?
      summon_doc = search.documents.first
      next unless summon_doc.present?

      # Summon gives you back different BookMarks for the same item!!
      # (depending on the query?)
      # This utterly confuses our list-management logic.
      # So, replace the new BookMark with the one we used for retrieval
      summon_doc.src['BookMark'] = bookmark

      docs[bookmark] = summon_doc
    end

    docs
  end

  # Render a true or false, for if the user is logged in
  def render_session_status
    Rails.logger.debug "status=#{!!current_user}"
    response.headers['Etag'] = '' # clear etags to prevent caching
    render plain: !!current_user, status: 200
  end

  def render_session_timeout
    flash[:notice] = 'Authenticated session been has timed out.  Now browsing anonymously.'
    # redirect_to "/login"
    redirect_to root_path
  end

  private

  def set_cache_headers
    if current_user
      response.headers['Cache-Control'] = 'no-cache, no-store'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
    end
  end

  # def by_source_config
  #   active_source = determine_active_source
  # end

  # NEXT-537 - logging in should not redirect you to the root path
  # from the Devise how-to docs...
  # https://github.com/plataformatec/devise/wiki/
  # How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update

  def store_location
    fullpath = request.fullpath
    # store this as the last-acccessed URL, except for exceptions...

    session[:previous_url] = fullpath unless
      # No AJAX ever
      request.xhr? ||
      # sign-in/out, part of the login process
      fullpath =~ /\/sign/ ||
      # exclude /users paths, which reflect the login process
      fullpath =~ /\/users/ ||
      fullpath =~ /\/backend/ ||
      fullpath =~ /\/catalog\/unapi/ ||
      fullpath =~ /\/catalog\/.*\.endnote/ ||
      fullpath =~ /\/catalog\/email/ ||
      # exclude lists VERBS, but don't wildcare /lists or viewing will break
      fullpath =~ /\/lists\/add/ ||
      fullpath =~ /\/lists\/move/ ||
      fullpath =~ /\/lists\/remove/ ||
      fullpath =~ /\/lists\/email/ ||
      # /spectrum/fetch - loading subpanels of bento-box aggregate
      fullpath =~ /\/spectrum/ ||
      # old-style async ajax holdings lookups - obsolete?
      fullpath =~ /\/holdings/ ||
      # Persistent selected-item lists
      fullpath =~ /\/selected/ ||
      # auto-timeout polling
      fullpath =~ /\/active/
  end

  # DEVISE callback
  # https://github.com/plataformatec/devise/wiki/ ...
  #     How-To:-Redirect-to-a-specific-page-on-successful-sign-in-and-sign-out
  def after_sign_in_path_for(_resource = nil)
    session[:previous_url] || root_path
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    cas_opts = YAML.load_file(File.join(Rails.root,'config','cas.yml'))[Rails.env] || {}

    # If CAS options are absent, we can only do application-level logout,
    # not CAS logout.  Warn, and proceed.
    unless cas_opts['host'] && cas_opts['logout_url']
      Rails.logger.error "CAS options missing - skipping CAS logout!"
      return root_path
    end
    
    # Full CAS logout + application logout page looks like this:
    # https://cas.columbia.edu/cas/logout?service=https://helpdesk.cul.columbia.edu/welcome/logout
    cas_logout_url = 'https://' + cas_opts['host'] + cas_opts['logout_url']
    service = request.base_url + root_path
    after_sign_out_path = "#{cas_logout_url}?service=#{service}"
    Rails.logger.debug "after_sign_out_path = #{after_sign_out_path}"
    return after_sign_out_path
  end

  protected

  def log_additional_data
    request.env['exception_notifier.url'] = {
      url: "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
    }
  end

  def add_alerts_to_documents(documents)
    documents = Array.wrap(documents)
    return if documents.length.zero?

    # fetch all alerts for current doc-set, in single query
    alerts = ItemAlert.where(source: 'catalog',
                             item_key: documents.map(&:id)).includes(:author)

    # loop over fetched alerts, adding them in to their documents
    alerts.each do |alert|
      this_alert_type = alert.alert_type

      # skip over no-longer-used alert types that may still be in the db table
      next unless ItemAlert::ALERT_TYPES.key?(this_alert_type)

      document = documents.find do |doc|
        doc.fetch('id').to_s == alert.item_key.to_s
      end

      document.item_alerts[this_alert_type] << alert

      document.active_item_alert_count ||= 0
      document.active_item_alert_count += 1 if alert.active?
    end
  end

  # # UNIX-5942 - work around spotty CUIT DNS
  # def cache_dns_lookups
  #   dns_cache = []
  #   hostnames = [ 'ldap.columbia.edu', 'cas.columbia.edu' ]
  #   hostnames.each { |hostname|
  #     addr = getaddress_retry(hostname)
  #     dns_cache << { 'hostname' => hostname, 'addr' => addr } if addr.present?
  #   }
  #   return unless dns_cache.size > 0
  #   
  #   Rails.logger.debug "cache_dns_lookups() dns_cache=#{dns_cache}"
  #   
  #   cached_resolver = Resolv::Hosts::Dynamic.new(dns_cache)
  #   Resolv::DefaultResolver.replace_resolvers( [cached_resolver, Resolv::DNS.new] )
  # end
  # 
  # def getaddress_retry(hostname = nil)
  #   return unless hostname.present?
  # 
  #   addr = nil
  #   (1..3).each do |try|
  #     begin
  #       addr = Resolv.getaddress(hostname)
  #       break if addr.present?
  #     rescue => ex
  #       # failed?  log, pause, and try again
  #       Rails.logger.error "Resolv.getaddress(#{hostname}) failed on try #{try}: #{ex.message}, retrying..."
  #       sleep 1
  #     end
  #   end
  # 
  #   return addr
  # end

end

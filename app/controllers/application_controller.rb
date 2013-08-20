class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::Catalog
  include Blacklight::Configurable
  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.
  check_authorization
  skip_authorization_check

  before_filter :apply_random_q
  before_filter :trigger_async_mode
  before_filter :trigger_debug_mode
  before_filter :by_source_config
  before_filter :log_additional_data
  before_filter :set_user_characteristics
  before_filter :condense_advanced_search_params

  # NEXT-537 - logging in should not redirect you to the root path
  # from the Devise how-to docs...
  # https://github.com/plataformatec/devise/wiki/
  # How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update
  after_filter :store_location

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  rescue_from ActionView::MissingTemplate do |exception|
    if request.format == "html"
      redirect_to root_url, :alert => exception.message
      return
    end

    Rails.logger.warn "request.format = #{request.format}"
    Rails.logger.warn "#{exception}"
    render nothing: true and return
  end

  def apply_random_q
    if params[:random_q]
      start = Time.now
      chosen_line = nil
      line_to_pick = rand(11917)
      input_file = File.join(Rails.root.to_s, "config", "opac_searches_sorted.txt")
      File.foreach(input_file).each_with_index do |line, number|
        chosen_line = line if number == line_to_pick
      end
      params['q'] = chosen_line
      params['s.q'] = chosen_line
    end
  end


  def condense_advanced_search_params
    new_hash = {}
    counter = 1
    (params['adv'] || {}).each_pair do |i, attrs|

      if attrs && !attrs['field'].to_s.empty? && !attrs['value'].to_s.empty?
        new_hash[counter.to_s] = attrs
        counter += 1
      end
    end
    params['adv'] = new_hash

  end

  def set_user_characteristics
    @user_characteristics =
    {
      # remote_ip gives back whatever's in X-Forwarded-For, which can
      # be manipulated by the client.  use remote_addr instead.
      # this will have to be revisited if/when clio lives behind a proxy.
      :ip => request.remote_addr,
      :on_campus => User.on_campus?(request.remote_addr),
      :authorized => !current_user.nil? || User.on_campus?(request.remote_addr)
    }
    @debug_entries[:user_characteristics] = @user_characteristics
  end

  def set_user_option
    session[:options] ||= {}
    session[:options][params['name']] = params['value']
    render :json => {:success => "Option set."}
  end

  def blacklight_search(sent_options = {})
    options = sent_options.deep_clone
    options['source'] = @active_source unless options['source']
    options['debug_mode'] = @debug_mode
    options['current_user'] = current_user

    # this new() actually runs the search.
    # [ the Solr engine call perform_search() within it's initialize() ]
    engine = Spectrum::Engines::Solr.new(options)

    if engine.successful?
      @response = engine.search
      @results = engine.documents
      if engine.total_items > 0
        look_up_clio_holdings(engine.documents)
        # Currently, item-alerts only show within the Databases data source
        if @active_source.present? and @active_source == "databases"
          add_alerts_to_documents(engine.documents)
        end
      end
    end

    @debug_entries ||= {}
    @debug_entries = @debug_entries.recursive_merge(engine.debug_entries)
    return engine

  end

  def look_up_clio_holdings(documents)
    clio_docs = documents.select { |d| d.get('clio_id_display')}

    if session[:async_off]
      begin
        unless clio_docs.empty?
          holdings = Voyager::Request.simple_holdings_check(
            connection_details: APP_CONFIG['voyager_connection']['oracle'],
            bibids: clio_docs.collect { |cd| cd.get('clio_id_display')} )
          clio_docs.each do |cd|
            cd['clio_holdings'] = holdings[cd.get('clio_id_display')]

          end

        end
      rescue => e
        logger.error "ApplicationController#look_up_clio_holdings exception: #{e}"
      end
    end

  end

  def trigger_async_mode
    if params.delete('async_off') == 'true'
      session[:async_off] = true
    elsif params.delete('async_on') == 'true'
      session[:async_off] = nil
    end
  end


  def trigger_debug_mode
    RSolr::Client.send(:include, RSolr::Ext::Notifications)
    RSolr::Client.enable_notifications!

    if params['debug_mode'] == 'on'
      @debug_mode = true
    elsif params['debug_mode'] == 'off'
      @debug_mode = false
    else
      @debug_mode ||= session['debug_mode'] || false
    end

    params.delete('debug_mode')
    session['debug_mode'] = @debug_mode

    unless current_user
      session['debug_mode'] == "off"
      @debug_mode = false
    end

    @current_user = current_user
    default_debug
  end

  def default_debug
    @debug_entries = Hash.arbitrary_depth
    @debug_entries['params'] = params
    @debug_entries['session'] = session
    # ENV is environment variables, but not the HTTP-related env variables
    # @debug_entries['environment'] = ENV
    @debug_entries['request.referer'] = request.referer
  end


  def determine_active_source
    if params['active_source']
      @active_source = params['active_source'].underscore
    else
      path_minus_advanced = request.path.to_s.gsub(/^\/advanced/, '')
      @active_source = case path_minus_advanced
      when /^\/databases/
        'databases'
      when /^\/new_arrivals/
        'new_arrivals'
      when /^\/catalog/
        'catalog'
      when /^\/articles/
        'articles'
      when /^\/journals/
        'journals'
      when /^\/dissertations/
        'dissertations'
      when /^\/ebooks/
        'ebooks'
      when /^\/academic_commons/
        'academic_commons'
      when /^\/library_web/
        'library_web'
      when /^\/newspapers/
        'newspapers'
      when /^\/archives/
        'archives'
      else
        params['active_source'] || 'quicksearch'
      end
    end
  end

  def blacklight_solr(source = @active_source)
    if self.respond_to?(:blacklight_config)
      @blacklight_solrs ||= {}
      @blacklight_solrs[source] || (@blacklight_solrs[source] = Spectrum::Engines::Solr.generate_rsolr(source))
    end
  end

  def blacklight_config(source = @active_source)
    if self.respond_to?(:blacklight_config)
      @blacklight_configs ||= {}
      @blacklight_configs[source] || (@blacklight_configs[source] = Spectrum::Engines::Solr.generate_config(source))
    end

  end

  def catch_404
    unrouted_uri = request.fullpath
    alert = "remote ip: #{request.remote_ip}   Invalid URL: #{unrouted_uri}"
    logger.warn alert
    redirect_to root_path, :alert => alert
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

    # We got a post - that is, a submitted form, with a "To" - send the email!
    if request.post?
      if params[:to]
        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}

        # if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
        if params[:to].match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/)
          # # Don't hit Solr until we actually need to fetch field data
          # @response, @documents =
          #   get_solr_response_for_field_values( SolrDocument.unique_key, params[:id] )
          # Yes, but IDs may be Catalog Bib keys or Summon FETCH IDs...
          @documents = ids_to_documents(params[:id])
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

  def ids_to_documents(id_array = [])
    document_array = []
    return document_array unless id_array.kind_of?(Array)
    return document_array if id_array.empty?

    # First, split into per-source lists,
    # (depend on Summon IDs to start with "FETCH"...)
    catalog_item_ids = []
    articles_item_ids = []
    Array.wrap(id_array).each do |item_id|
      if item_id.start_with?("FETCH")
        articles_item_ids.push item_id
      else
        catalog_item_ids.push item_id
      end
    end

    catalog_document_list = []
    if catalog_item_ids.any?
      # Then, do two source-specific set-of-id lookups
      extra_solr_params = {
        :rows => catalog_item_ids.size
      }
      response, catalog_document_list = get_solr_response_for_field_values(SolrDocument.unique_key, catalog_item_ids, extra_solr_params)
    end

    article_document_list = []
    if articles_item_ids.any?
      article_document_list = get_summon_docs_for_id_values(articles_item_ids)
    end

    # Then, merge back, in original order
    key_to_doc_hash = {}
    catalog_document_list.each do |doc|
      key_to_doc_hash[ doc[:id] ] = doc
    end
    article_document_list.each do |doc|
      key_to_doc_hash[ doc.id ] = doc
    end

    id_array.each do |id|
      document_array.push key_to_doc_hash[id]
    end
    document_array
  end



  def get_summon_docs_for_id_values(id_array)
    return [] unless id_array.kind_of?(Array)
    return [] if id_array.empty?

    @params = {
      'spellcheck' => true,
      's.ho' => true,
      # 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article)',
      # 's.ff' => ['ContentType,and,1,5', 'SubjectTerms,and,1,10', 'Language,and,1,5']
    }

    @config = APP_CONFIG['summon']
    @config.merge!(:url => 'http://api.summon.serialssolutions.com/2.0.0')
    @config.symbolize_keys!


    @params['s.cmd'] ||= "setFetchIDs(#{id_array.join(',')})"


    @params['s.q'] ||= ''
    @params['s.fq'] ||= ''
    @params['s.role'] ||= ''

    @errors = nil
    begin
      @service = ::Summon::Service.new(@config)

      Rails.logger.info "[Spectrum][Summon] config: #{@config}"
      Rails.logger.info "[Spectrum][Summon] params: #{@params}"

      ### THIS is the actual call to the Summon service to do the search
      @search = @service.search(@params)

    rescue Exception => e
      Rails.logger.error "[Spectrum][Summon] error: #{e.message}"
      @errors = e.message
    end
# - raise
    # we choose to return empty list instead of nil
    @search ? @search.documents : []
  end




  private


  def by_source_config
    @active_source = determine_active_source
  end

  # NEXT-537 - logging in should not redirect you to the root path
  # from the Devise how-to docs...
  # https://github.com/plataformatec/devise/wiki/
  # How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update

  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless
      request.fullpath =~ /\/users/ or
      request.fullpath =~ /\/backend/ or
      request.fullpath =~ /\/catalog\/unapi/ or
      # exclude lists VERBS, but don't wildcare /lists or viewing will break
      request.fullpath =~ /\/lists\/add/ or
      request.fullpath =~ /\/lists\/move/ or
      request.fullpath =~ /\/lists\/remove/ or
      request.fullpath =~ /\/lists\/email/
      # /spectrum/fetch - loading subpanels of bento-box aggregate
      request.fullpath =~ /\/spectrum/
      # old-style async ajax holdings lookups - obsolete?
      request.fullpath =~ /\/holdings/
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end


  protected

  def log_additional_data
    request.env["exception_notifier.url"] = {
      url: "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
    }
  end

  def add_alerts_to_documents(documents)
    documents = Array.wrap(documents)
    return if documents.length == 0
    query = ItemAlert.where(:source => 'catalog', :item_key=> Array.wrap(documents).collect(&:id)).includes(:author)

    query.each do |alert|
      document = documents.detect { |doc| doc.get('id').to_s == alert.item_key.to_s }
      document["_item_alerts"] ||= {}
      document["_active_item_alert_count"] ||= 0
      ItemAlert::ALERT_TYPES.each do |alert_type, name|
        document["_item_alerts"][alert_type] ||= []
        if alert_type == alert.alert_type
          document["_item_alerts"][alert.alert_type] << alert
          if alert.active?
            document["_active_item_alert_count"] += 1
          end
        end
      end
    end
  end


end


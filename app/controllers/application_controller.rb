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
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def apply_random_q
    if params[:random_q]
      start = Time.now
      chosen_line = nil
      line_to_pick = rand(11917)
      File.foreach(File.join(Rails.root.to_s, "config", "opac_searches_sorted.txt")).each_with_index do |line, number|
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
      look_up_clio_holdings(engine.documents)
      add_alerts_to_documents(engine.documents)
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
          holdings = Voyager::Request.simple_holdings_check(connection_details: APP_CONFIG['voyager_connection']['oracle'], bibids: clio_docs.collect { |cd| cd.get('clio_id_display')})
          clio_docs.each do |cd|
            cd['clio_holdings'] = holdings[cd.get('clio_id_display')]

          end

        end
      rescue Exception => e
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

    @debug_entries = Hash.arbitrary_depth

    @current_user = current_user

    default_debug

  end

  def default_debug
    @debug_entries['params'] =params
    @debug_entries['session'] = session
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



  private


  def by_source_config
    @active_source = determine_active_source
  end



  protected
  def log_additional_data
    request.env["exception_notifier.url"] = {
      url: "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
    }
  end

  def add_alerts_to_documents(documents)
    documents = Array.wrap(documents)
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


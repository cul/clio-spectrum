class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller
  include Blacklight::Catalog
  include Blacklight::Configurable
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 
  check_authorization
  skip_authorization_check

  before_filter :trigger_debug_mode
  before_filter :by_source_config
  before_filter :log_additional_data

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end


  def blacklight_search(options = {})
    options[:source] = @active_source unless options[:source]
    options[:debug_mode] = @debug_mode
    engine = Spectrum::Engines::Solr.new(options)
    resp, results = engine.search
    return resp, results

  end

  def look_up_clio_holdings(documents)
    clio_docs = documents.select { |d| d.get('clio_id_display')}
    
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




  private
  def configure_search(source)
    if self.respond_to?(:blacklight_config) 
      Blacklight.solr = Spectrum::Engines::Solr.generate_rsolr(source) 
      self.blacklight_config = Spectrum::Engines::Solr.generate_config(source)
    end
  end

  def by_source_config
    @active_source = determine_active_source
    configure_search(@active_source)
  end



  protected
  def log_additional_data
    request.env["exception_notifier.url"] = {
      url: "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
    }
  end

end


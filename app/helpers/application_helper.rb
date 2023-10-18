# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def application_name
    APP_CONFIG['application_name'].to_s
  end

  def alternating_line(id = 'default')
    @alternating_line ||= Hash.new('odd')
    @alternating_line[id] = @alternating_line[id] == 'even' ? 'odd' : 'even'
  end

  def determine_search_params
    # raise
    if params['action'] == 'show'
      return session['save_search'] if session['save_search']
      return session['search'] || {}
    end
    session['save_search'] = params if params['q']
    params
  end

  # Copy functionality of BlackLight's sidebar_items,
  # new deprecated, over to CLIO-specific version
  # collection of items to be rendered in the @sidebar
  def clio_sidebar_items
    @clio_sidebar_items ||= []
  end
  
  def confetti?
    return false unless confetti_config = APP_CONFIG['confetti']
    if confetti_ips = confetti_config['ips']
      return true if confetti_ips.include? request.remote_addr
    end
    if confetti_unis = confetti_config['unis'] && current_user && current_user.uid
      return true if confetti_unis.include? current_user.uid
    end
    return false
  end
  
  def yes_button
    link_to "YES", "javascript:toggleConfetti()", class: 'btn btn-success btn-lg center-block'
  end
end

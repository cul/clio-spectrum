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
      return session['save_search']  if session['save_search']
      return session['search'] || {}
    end
    if params['q']
      session['save_search'] = params
    end
    return params
  end

  # Copy functionality of BlackLight's sidebar_items,
  # new deprecated, over to CLIO-specific version
  # collection of items to be rendered in the @sidebar
  def clio_sidebar_items
    @clio_sidebar_items ||= []
  end

  def clio_uptime
    time_ago_in_words(Clio::BOOTED_AT)
  end

end

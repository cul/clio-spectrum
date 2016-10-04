module PreferenceSupport


  def get_user_summon_facets
    # raise
    return nil unless current_user
    preference = Preference.find_by(login: current_user.login )
    return nil unless preference
    settings = YAML.load(preference['settings']) || {}
    return nil unless settings
    return settings[:summon_facets] || nil
  end



  # Application defaults with user overrides
  def get_summon_facets
    get_user_summon_facets() ||
    get_system_summon_facets() ||
    []
  end

  # Application defaults
  DEFAULT_SUMMON_FACETS = {
    'ContentType' => 10, 'SubjectTerms' => 10, 'Language' => 10
  }
  def get_system_summon_facets
    APP_CONFIG['summon_facets'] ||
    DEFAULT_SUMMON_FACETS ||
    []
  end



  # list of all datasources known to work within bentos
  BENTO_DATASOURCES = [
    'catalog', 'articles', 'academic_commons', 'library_web',
    'geo', 'dlc'
  ]

  def get_user_search_layout(layout)
    return nil unless current_user
    preference = Preference.find_by(login: current_user.login )
    return nil unless preference
    settings = YAML.load(preference['settings']).with_indifferent_access || {}
    return nil unless settings
    return nil unless settings.has_key?(:search_layouts)
    return nil unless settings[:search_layouts].has_key?(layout)
    return settings[:search_layouts][layout] || nil
  end

  # Application defaults with user overrides
  def get_search_layout(layout)
    get_user_search_layout(layout) ||
    get_system_search_layout(layout) ||
    nil
  end

  def get_system_search_layout(layout)
    # environment-specific app_config.yml
    if APP_CONFIG.has_key?('search_layouts') &&
       APP_CONFIG['search_layouts'].has_key?(layout)
      return APP_CONFIG['search_layouts'][layout]
    end

    # defaults file - searches.yml
    if SEARCHES_CONFIG.has_key?('default_search_layouts') &&
       SEARCHES_CONFIG['default_search_layouts'].has_key?(layout)
      return SEARCHES_CONFIG['default_search_layouts'][layout]
    end

    # not found - return nil
    nil
  end



end





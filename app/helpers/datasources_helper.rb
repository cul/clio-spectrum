#encoding: UTF-8
module DatasourcesHelper
  SOURCES_ALWAYS_INCLUDED = ['Quicksearch', 'Catalog', 'Articles & Journals', 'Academic Commons', 'Library Web']
  SOURCES_MINOR = ['Archives', 'Databases', 'Dissertations', 'eBooks', 'New Arrivals', 'Newspapers']
  SOURCES_NO_FACETS = ['Quicksearch', 'Articles & Journals', 'Dissertations', 'eBooks', 'Library Web']
  SOURCES_HIDDEN = { 'Articles & Journals' => ['Articles', 'eJournals']}
  

  def all_datasources
    SOURCES_ALWAYS_INCLUDED | SOURCES_MINOR | SOURCES_HIDDEN.values.flatten.uniq
  end

  def active_query?()
    !(params['q'].to_s.empty? && params.keys.all? { |k| !k.include?('s.') } && params['f'].to_s.empty? && params['commit'].to_s.empty?)

  end
  
  def add_all_datasource_landing_pages
    content_tag('div', :class => 'landing_pages') do
      all_datasources.collect do |source|
        datasource_landing_page(source)
      end.join('').html_safe
    end
  
  end

  def datasource_landing_page(title)
    datasource = datasource_to_class(title)
    classes = ['landing_page', datasource] 
    classes << 'selected' if title == @active_source 
    content_tag(:div, render(:partial => "/_search/landing_pages/#{datasource}"), :class => classes.join(' '))
  end

  def datasources_active_list(options = {})
    if options[:all_sources]
      SOURCES_ALWAYS_INCLUDED | SOURCES_MINOR
    else
      SOURCES_ALWAYS_INCLUDED | SOURCES_MINOR.select { |s| s == options[:active] }
    end
  end

  def datasources_hidden_list(options = {})
    if options[:all_sources]
      []
    else
      SOURCES_MINOR.reject { |s| s == options[:active] }
    end
  end

  def add_datasources(active)
    options = {
      :active => active,
      :query => params['q'] || params['s.q'] || ""
    }
    
    options[:all_sources] = !active_query? || SOURCES_NO_FACETS.include?(active)

    result = []
    #result << [content_tag(:li, 'Sources', :class => 'title')]
    result |= datasources_active_list(options).collect { |src| datasource_item(src,options) }

    unless (hidden_datasources = datasources_hidden_list(options)).empty?
      result << content_tag(:li, link_to("More", "#"),  :id => "datasource_expand")

      sub_results = hidden_datasources.collect { |src| datasource_item(src,options) }
      
      sub_results << content_tag(:li, link_to("Fewer", "#", :id => "datasource_contract"))
      result << content_tag(:ul, sub_results.join('').html_safe, :id => 'expanded_datasources')
    end

    landing_class = options[:all_sources] ? 'landing' : ''
    sidebar_items.unshift(content_tag(:ul, result.join('').html_safe, :id => "datasources", :class => landing_class))
  end

  def datasource_to_class(source)
    source.to_s.gsub(/ & /,'_').gsub(/ /, '_').underscore
  end

  def datasource_to_facet(source)
    if source == "eJournals"
      'ejournals'
    else 
      datasource_to_class(source)
    end
  end

  def datasource_item(source, options)
    classes = []
    classes << 'minor_source' if options[:minor]
    query = options[:query]



    li_classes = %w{datasource_link}
    li_classes << "selected" if source == options[:active]
    li_classes << "subsource" if options[:subsource]

    href = unless active_query?()
      '#'
    else
      case source
      when 'Quicksearch'
        {:controller => 'search', :q => query}
      when 'Catalog'
        {:controller => 'catalog', :q => query}
      when 'Databases'
        databases_index_path(:q => query)
      when 'Articles & Journals'
        {:controller => 'search', :action => 'articles_journals', :q => query}
      when 'Articles'
        {:controller => 'articles', :action => 'search', 'new_search' => true, 's.q' => query}
      when 'eJournals'
        ejournals_index_path(:q => query)
      when 'eBooks'
        {:controller => 'search', :action => 'ebooks', :q => query}
      when 'Dissertations'
        {:controller => 'search', :action => 'dissertations', :q => query}
      when 'Newspapers'
        {:controller => 'search', :action => 'newspapers', :q => query}
      when 'New Arrivals'
        new_arrivals_index_path(:q => query)
      when 'Academic Commons'
        academic_commons_index_path(:q => query)
      when 'Library Web'
        library_web_index_path(:q => query)
      when 'Archives'
        archives_index_path(:q => query)
      end
    end

    result = content_tag(:li, link_to(source, href, :class => classes.join(" ")),  :source => datasource_to_class(source), :class => li_classes.join(" "))


    if (sub_sources = SOURCES_HIDDEN[source])
      sub_sources.each { |ss| result += datasource_item(ss, options.merge(:subsource => true))}
    end


    result
  end

  def datasource_switch_link(title, source, *args)
    options = args.extract_options!
    options[:class] ||= ""
    options[:class] += " datasource_link"
    options[:source] = source

    link_to title, "#", options
  end
end

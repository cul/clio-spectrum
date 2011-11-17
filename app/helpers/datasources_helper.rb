#encoding: UTF-8
module DatasourcesHelper
  SOURCES_ALWAYS_INCLUDED = ['Quicksearch', 'Catalog', 'Articles']
  SOURCES_MINOR = ['eBooks', 'New Arrivals']
  
  def add_all_datasource_landing_pages
    (SOURCES_ALWAYS_INCLUDED | SOURCES_MINOR).collect do |source|
      datasource_landing_page(source)
    end.join('').html_safe
  
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
    
    options[:all_sources] = options[:query].to_s.empty?

    result = [content_tag(:li, 'Sources', :class => 'title')]

    result |= datasources_active_list(options).collect { |src| datasource_link(src,options) }

    unless (hidden_datasources = datasources_hidden_list(options)).empty?
      result << content_tag(:li, link_to("More", "#"),  :id => "datasource_expand")

      sub_results = hidden_datasources.collect { |src| datasource_link(src,options) }
      
      sub_results << content_tag(:li, link_to("Fewer", "#", :id => "datasource_contract"))
      result << content_tag(:ul, sub_results.join('').html_safe, :id => 'expanded_datasources')
    end

    landing_class = options[:all_sources] ? 'landing' : ''
    sidebar_items << content_tag(:ul, result.join('').html_safe, :id => "datasources", :class => landing_class)
  end

  def datasource_to_class(source)
    source.to_s.gsub(/ /, '_').underscore
  end

  def datasource_link(source, options)
    classes = []
    classes << 'minor_source' if options[:minor]
    query = options[:query]

    li_classes = source == options[:active] ? "selected" : ""

    href = if query.empty?
      '#'
    else
      case source
      when 'Quicksearch'
        {:controller => 'search', :q => query}
      when 'Catalog'
        {:controller => 'catalog', :q => query}
      when 'Articles'
        {:controller => 'articles', :action => 'search', 'new_search' => true, 's.q' => query}
      when 'eBooks'
        {:controller => 'search', :action => 'ebooks', :q => query}
      when 'New Arrivals'
        {:controller => 'catalog', :action => 'index', :q => query, :f => {"acq_date_facet" => ["Last 3 Months"]}, :active_source => 'New Arrivals'}
      end
    end

    content_tag(:li, link_to(source, href, :class => classes.join(" ")),  :source => datasource_to_class(source), :class => li_classes)

  end

end

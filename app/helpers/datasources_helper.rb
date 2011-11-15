#encoding: UTF-8
module DatasourcesHelper
  SOURCES_ALWAYS_INCLUDED = ['Quicksearch', 'Articles', 'Catalog']
  SOURCES_MINOR = ['eBooks', 'New Arrivals']

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

  def render_datasources(options = {})
    options.reverse_merge!(:all_sources => false)

    result = []

    datasources_active_list(options).each do |source|
      result << datasource_link(source,options)
    end

    result.join('').html_safe
  end

  def datasource_link(source, options)

    classes = (source == options[:active] ? 'selected' : '')
    query = options[:query].to_s

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
        {:controller => 'catalog', :action => 'index', :q => query, :f => {"acq_date_facet" => ["Last 3 Months"]}}
      end
    end

    content_tag(:li, link_to(source, href, :class => classes),  :source => source.underscore)

  end

end

#encoding: UTF-8
module DatasourcesHelper
  

  def datasource_list(category = :all)
    results = []
    results |= DATASOURCES_CONFIG['datasource_bar']['major_sources'] if category.in?(:all, :major)
    results |= DATASOURCES_CONFIG['datasource_bar']['minor_sources'] if category.in?(:all, :minor)
    results
  end

  def active_query?()
    !(params['q'].to_s.empty? && params.keys.all? { |k| !k.include?('s.') } && params['f'].to_s.empty? && params['commit'].to_s.empty?)

  end
  
  def add_all_datasource_landing_pages
    content_tag('div', :class => 'landing_pages') do
      datasource_list(:all).collect do |source|
        datasource_landing_page(source)
      end.join('').html_safe
    end
  
  end

  def datasource_landing_page(source)
    classes = ['landing_page', source] 
    classes << 'selected' if source == @active_source 
    content_tag(:div, render(:partial => "/_search/landing_pages/#{source}"), :class => classes.join(' '))
  end

  def datasources_active_list(options = {})
    if options[:all_sources]
      datasource_list(:all)
    else
      datasource_list(:major) | datasource_list(:minor).select { |s| s == options[:active] }
    end
  end

  def datasources_hidden_list(options = {})
    if options[:all_sources]
      []
    else
       datasource_list(:minor).reject { |s| s == options[:active] }
    end
  end

  def add_datasources(active)
    options = {
      :active => active,
      :query => params['q'] || params['s.q'] || ""
    }
    

    options[:all_sources] = !active_query? || DATASOURCES_CONFIG['datasources'][active]['no_facets']

    result = []
    result |= datasources_active_list(options).collect { |src| datasource_item(src,options) }

    unless (hidden_datasources = datasources_hidden_list(options)).empty?
      result << content_tag(:li, link_to("More", "#"),  :id => "datasource_expand")

      sub_results = hidden_datasources.collect { |src| datasource_item(src,options) }
      
      sub_results << content_tag(:li, link_to("Fewer", "#", :id => "datasource_contract"))
      result << content_tag(:ul, sub_results.join('').html_safe, :id => 'expanded_datasources')
    end

    landing_class = options[:all_sources] ? 'landing datasource_list' : 'datasource_list'
    sidebar_items.unshift(content_tag(:ul, result.join('').html_safe, :id => "datasources", :class => landing_class))
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
      when 'quicksearch'
        {:controller => 'search', :q => query}
      when 'catalog'
        {:controller => 'catalog', :q => query}
      when 'databases'
        databases_index_path(:q => query)
      when 'articles'
        {:controller => 'articles', :action => 'search', 'new_search' => true, 's.q' => query}
      when 'journals'
        journals_index_path(:q => query)
      when 'ebooks'
        {:controller => 'search', :action => 'ebooks', :q => query}
      when 'dissertations'
        {:controller => 'search', :action => 'dissertations', :q => query}
      when 'newspapers'
        {:controller => 'search', :action => 'newspapers', :q => query}
      when 'new_arrivals'
        new_arrivals_index_path(:q => query)
      when 'academic_commons'
        academic_commons_index_path(:q => query)
      when 'library_web'
        library_web_index_path(:q => query)
      when 'archives'
        archives_index_path(:q => query)
      end
    end

    raise "no source data found for #{source}" unless DATASOURCES_CONFIG['datasources'][source]
    content_tag(:li, link_to(DATASOURCES_CONFIG['datasources'][source]['name'], href, :class => classes.join(" ")),  :source => source, :class => li_classes.join(" "))




  end

  def datasource_switch_link(title, source, *args)
    options = args.extract_options!
    options[:class] ||= ""
    options[:class] += " datasource_link"
    options[:source] = source

    link_to title, "#", options
  end
end

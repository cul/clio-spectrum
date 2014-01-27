#encoding: UTF-8
module DatasourcesHelper


  def datasource_list(category = :all)
    results = []
    results |= DATASOURCES_CONFIG['datasource_bar']['major_sources'] if category.in?(:all, :major)
    results |= DATASOURCES_CONFIG['datasource_bar']['minor_sources'] if category.in?(:all, :minor)
    results
  end

  def active_query?()
    !( params['q'].to_s.empty? &&
       params.keys.all? { |k| !k.include?('s.') } &&
       params['f'].to_s.empty? &&
       params['commit'].to_s.empty?
    )
  end

  # switch from loading all landing-pages/switching via javascript
  # to loading only single-source landing-page, select with page-fetch
  # def add_all_datasource_landing_pages
  #   content_tag('div', :class => 'landing_pages') do
  #     datasource_list(:all).collect do |source|
  #       datasource_landing_page(source)
  #     end.join('').html_safe
  #   end
  # end

  # Output the HTML of a single landing page for the passed data-source
  def datasource_landing_page(source = @active_source)
    content_tag('div', :class => 'landing_pages') do
      classes = ['landing_page', source]
      classes << 'selected' if source == @active_source
      search_config = SEARCHES_CONFIG['sources'][source]
      warning = search_config ? search_config['warning'] : nil;
      content_tag(:div, render(:partial => "/_search/landing_pages/#{source}", :locals => {warning: warning}), :class => classes.join(' '))
    end
  end

  def datasources_active_list(options = {})
    if options[:all_sources]
      datasource_list(:all)
    else
      datasource_list(:major) |
      datasource_list(:minor).select { |source| source == options[:active_source] }
    end
  end

  # Return a list of datasources which are "hidden" beneath the "More..." expander
  def datasources_hidden_list(options = {})
    if options[:all_sources]
      []
    else
       datasource_list(:minor).reject { |source| source == options[:active_source] }
    end
  end

  # Called from several layouts to add the stack of datasources to the sidebar.
  # Takes as arg the source to mark as active.
  # Returns an HTML <UL> list of datasources
  def add_datasources(active_source = @active_source)
    options = {
      :active_source => active_source,
      :query => params['q'] || params['s.q'] || ""
    }

    has_facets = source_has_facets?(active_source)
    # Show all datasources when there's no current query, or 
    # when we're in a datasource that doesn't have facets.
    options[:all_sources] = !active_query? || !has_facets

    result = []
    result |= datasources_active_list(options).collect { |src|
      single_datasource_list_item(src, options)
    }

    # If there are hidden data-sources, gather them up wrapped w/ expand/contract links
    unless (hidden_datasources = datasources_hidden_list(options)).empty?
      result << content_tag(:li, link_to("More...", "#"),  :id => "datasource_expand")

      sub_results = hidden_datasources.collect { |src|
        single_datasource_list_item(src, options)
      }

      sub_results << content_tag(:li, link_to("Fewer...", "#"), :id => "datasource_contract")
      result << content_tag(:ul, sub_results.join('').html_safe, :id => 'expanded_datasources')
    end

    landing_class = options[:all_sources] ? 'landing datasource_list' : 'datasource_list'
    landing_class += " no_facets" unless has_facets
    clio_sidebar_items.unshift(
      content_tag(:ul, result.join('').html_safe, :id => "datasources", :class => landing_class)
    )
  end


  def sidebar_span(source = @active_source)
    source_has_facets?(source) ? "span3" : "span2_5"
  end

  def main_span(source = @active_source)
    source_has_facets?(source) ? "span9" : "span9_5"
  end


  # Will there be any facets shown for this datasource?
  # No, if we're on the landing page, or if the datasource has no facets.
  # Otherwise, yes.
  def source_has_facets?(source = @active_source)
    # old mystery
    # (@has_facets || !DATASOURCES_CONFIG['datasources'][source]['no_facets'] && !@show_landing_pages)

    # mysterious
    # return true if @has_facets

    # No facets if we're showing the landing pages instead of query results
    return false if @show_landing_pages

    # No facets, if this datasource explicitly says so
    return false if DATASOURCES_CONFIG['datasources'][source]['no_facets']

    # Otherwise, always show the facets
    return true
  end


  # Build up the HTML of a single datasource link, to be used along the left-side menu.
  # Should be an <li>, with an <a href> inside it.
  # The link should re-run the current search against the new data-source.
  def single_datasource_list_item(source, options)
    classes = []
    classes << 'minor_source' if options[:minor]
    query = options[:query]

    li_classes = %w{datasource_link}
    li_classes << "selected" if source == options[:active_source]
    li_classes << "subsource" if options[:subsource]

    # What parts of a query should we carry-over between data-sources?
    # -- Any basic query term, yes, query it against the newly selected datasources
    # -- Any facets?  Drop them, clear all filtering when switching datasources.
    # NEXT-954 - Improve Landing Page access
    href = if query.empty?
      # Don't carry-over the null query, just link to new datasource's landing page
      "/#{source}"
    else
      case source
      when 'quicksearch'
        quicksearch_index_path(:q => query)
      when 'catalog'
        base_catalog_index_path(:q => query)
      when 'databases'
        databases_index_path(:q => query)
      when 'articles'
        articles_index_path('s.q' => query, 'new_search' => true)
      when 'journals'
        journals_index_path(:q => query)
      when 'ebooks'
        ebooks_index_path(:q => query)
      when 'dissertations'
        dissertations_index_path(:q => query)
      when 'newspapers'
        newspapers_index_path(:q => query, 'new_search' => true)
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
    content_tag(:li,
      link_to(DATASOURCES_CONFIG['datasources'][source]['name'],
          href,
          :class => classes.join(" ")
      ),
      :source => source,
      :class => li_classes.join(" ")
    )

  end


  def datasource_switch_link(title, source, *args)
    options = args.extract_options!
    options[:class] ||= ""
    options[:class] += " datasource_link"
    options[:source] = source

    link_to title, "#", options
  end

end

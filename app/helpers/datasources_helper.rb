# encoding: UTF-8
module DatasourcesHelper

  def get_datasource_bar
    APP_CONFIG['datasource_bar'] ||
      DATASOURCES_CONFIG['default_datasource_bar'] || []
  end

  def datasource_list(category = :all)
    results = []
    results |= get_datasource_bar['major_sources'] if category.in?(:all, :major)
    results |= get_datasource_bar['minor_sources'] if category.in?(:all, :minor)

    results
  end

  def active_query?
    !( params['q'].to_s.empty? &&
       params.keys.all? { |k| !k.include?('s.') } &&
       params['f'].to_s.empty? &&
       params['commit'].to_s.empty?
    )
  end


  # Output the HTML of a single landing page for the passed data-source
  def datasource_landing_page(datasource = $active_source)
    content_tag('div', class: 'landing_pages') do
      classes = ['landing_page', datasource]
      classes << 'selected' if datasource == $active_source
      search_config = DATASOURCES_CONFIG['datasources'][datasource]
      warning = search_config ? search_config['warning'] : nil
      content_tag(:div,
                  render(partial: "/landing_pages/#{datasource}",
                         locals: { warning: warning }),
                  class: classes.join(' '),
                  data: { 'ga-action' => 'Landing Page Click' }
                  )
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
  def add_datasources(active_source = $active_source)
    options = {
      active_source: active_source,
      query: params['q'] || params['s.q'] || nil
    }

    has_facets = source_has_facets?(active_source)
    # Show all datasources when there's no current query, or
    # when we're in a datasource that doesn't have facets.
    options[:all_sources] = !active_query? || !has_facets

    result = []
    result |= datasources_active_list(options).map do |src|
      single_datasource_list_item(src, options)
    end

    # If there are hidden data-sources, gather them up wrapped w/ expand/contract links
    unless (hidden_datasources = datasources_hidden_list(options)).empty?
      result << content_tag(:li, link_to('More...', '#'),  id: 'datasource_expand')

      sub_results = hidden_datasources.map do |src|
        single_datasource_list_item(src, options)
      end

      sub_results << content_tag(:li, link_to('Fewer...', '#'), id: 'datasource_contract')
      result << content_tag(:ul, sub_results.join('').html_safe, id: 'expanded_datasources', class: 'list-unstyled')
    end

    landing_class = options[:all_sources] ? 'landing datasource_list' : 'datasource_list'
    landing_class += ' no_facets' unless has_facets
    landing_class += ' hidden-xs'
    clio_sidebar_items.unshift(
      content_tag(:ul, result.join('').html_safe, id: 'datasources', class: landing_class)
    )
  end

  def sidebar_span(source = $active_source)
    'col-sm-3'
  end

  def main_span(source = $active_source)
    'col-sm-9'
  end

  # Will there be any facets shown for this datasource?
  # No, if we're on the landing page, or if the datasource has no facets.
  # Otherwise, yes.
  def source_has_facets?(source = $active_source)
    # No facets if we're showing the landing pages instead of query results
    return false if @show_landing_pages

    # If this 'source' doesn't have a configuration, then no facets
    return false unless DATASOURCES_CONFIG['datasources'][source]

    # No facets, if this datasource explicitly says so
    return false if DATASOURCES_CONFIG['datasources'][source]['no_facets']

    # Otherwise, always show the facets
    true
  end

  # Build up the HTML of a single datasource link, to be used along the left-side menu.
  # Should be an <li>, with an <a href> inside it.
  # The link should re-run the current search against the new data-source.
  def single_datasource_list_item(datasource, options)
    link_classes = []
    # link_classes << 'subsource' if get_datasource_bar['subsources'].include?(source)

    query = options[:query]

    li_classes = %w(datasource_link)
    li_classes << 'selected' if datasource == options[:active_source]
    li_classes << 'subsource' if get_datasource_bar['subsources'].include?(datasource)

    # li_classes << 'subsource' if options[:subsource]
    # li_classes << 'subsource' if get_datasource_bar['subsources'].include?(source)

    href = datasource_landing_page_path(datasource, query)
    datasource_link = single_datasource_link(datasource, href, link_classes)
    datasource_hits = single_datasource_hits(datasource, query)

    # What parts of a query should we carry-over between data-sources?
    # -- Any basic query term, yes, query it against the newly selected datasources
    # -- Any facets?  Drop them, clear all filtering when switching datasources.
    # NEXT-954 - Improve Landing Page access

    fail "no source data found for #{datasource}" unless DATASOURCES_CONFIG['datasources'][datasource]

    content_tag(:li,
                datasource_link + datasource_hits,
                source: datasource,
                class: li_classes.join(' ')
    )
  end



  def single_datasource_link(datasource, href, link_classes)
    link = link_to(DATASOURCES_CONFIG['datasources'][datasource]['name'],
            href,
            class: link_classes.join(' ')
    )
    content_tag(:span, link, class: 'datasource-label')
  end

  def single_datasource_hits(datasource, query)
    hits_class = 'datasource-hits'
    hits_data = ''

    # Set default based on app_config control.  If unset, disable feature.
    fetch_hits = APP_CONFIG['fetch_datasource_hits'] || false

    # Breck asks that we display hit-count for current source
    # fetch_hits = false if datasource == $active_source

    # NEXT-1359 - hit counts
    # fetch_hits = false if query.nil? || query.length < 2
    # fetch_hits = false if datasource == 'quicksearch'

    fetch_hits = false if get_datasource_bar['major_sources'].exclude?(datasource)
    fetch_hits = false if get_datasource_bar['minor_sources'].include?(datasource)

    # NEXT-1366 - zero hit count for website null search
    fetch_hits = false if (datasource == 'library_web' && (query.nil? || query.empty?))

    # NEXT-1368 - suppress data source hit counts in certain situations
    # If the params have any of the no-hits keys, don't do hits.
    no_hits = [ 'f', 'range', ]
    fetch_hits = false if no_hits.any? { |nope| params.key? nope }

    # I'm having trouble generating accurate hit-counts for Summon queries.
    # Disable for now - show no hitcounts within Summon
    fetch_hits = false if $active_source == 'articles'

    if fetch_hits
      hits_url = spectrum_hits_path(datasource: datasource, q: query, new_search: true)
      hits_data = { hits_url: hits_url }
      hits_class = hits_class + ' fetch'
    end

    # if get_datasource_bar['major_sources'].include?(source)
    #   if get_datasource_bar['subsources'].exclude?(source)
    #     if source != $active_source
    #       if query && query.length > 1
    #         hits_url = spectrum_hits_path(source: source, q: query, new_search: true)
    #         hits_data = { hits_url: hits_url }
    #         # span_data[:query] = query.merge( {source: source, new_search: true} )
    #         hits_class = hits_class + ' fetch'
    #       end
    #     end
    #   end
    # end

    content_tag(:span, '', class: hits_class, data: hits_data)
  end




  def datasource_landing_page_path(source, query = nil)
    # What parts of a query should we carry-over between data-sources?
    # -- Any basic query term, yes, query it against the newly selected datasources
    # -- Any facets?  No, Drop them, clear all filtering when switching datasources.

    # # NEXT-954 - Improve Landing Page access
    # if query.empty?
    #   # Don't carry-over the null query, just link to new datasource's landing page
    #   return "/#{source}"
    # end

    # NEXT-1367 - Re-execute null search in new datasources
    if query.nil?
      # When there's no query, link to datasource's landing page
      return "/#{source}"
    end

    if source == 'articles'
      return articles_index_path('q' => query, 'new_search' => true)
    end

    return "/#{source}?" + {q: query}.to_query
  end

  def datasource_switch_link(title, source, *args)
    options = args.extract_options!
    options[:class] ||= ''
    options[:class] += ' datasource_link'
    options[:source] = source

    # link_to title, "#", options
    link_to title, source, options
  end

  # Used for building cache keys, following suggestions from:
  #    http://veerasundaravel.wordpress.com/2012/10/10
  # Fix bug of crawlers submitting bad params to landing-pages, creating
  # cached version of landing page with (invalid) embedded hidden query params.
  def params_digest
    return Digest::SHA1.hexdigest(params.sort.flatten.join("_"))
  end
end

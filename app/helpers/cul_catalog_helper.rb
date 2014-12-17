# encoding: UTF-8
#
module CulCatalogHelper
  def fix_catalog_links(text, source = @active_source)
    text.to_s.gsub('/catalog', "/#{source}").html_safe
  end

  def build_link_back(id = nil)
    # 1) EITHER start basic - just go back to where we came from... even if
    # it was a link found on a web page or in search-engine results...
    # link_back = request.referer.path
    # 2) OR have no "back" support unless the below works:
    link_back = nil
    # raise
    begin

      # Jump to the current item within the search results?
      # No - because simple anchor behavior is to scroll so that
      # the anchor is top-most in viewport.  This means that
      # the search-box is always hidden, even for first document.
      # current_search_session.query_params.merge!(anchor: id)

      # add some extra info to the "Back to Results" link
      opts = {class: 'link_back'}

      # I don't think we use this at this time - might be handy someday.
      # opts['data'] = {bib: id} if id

      # try the Blacklight approach of reconstituting session[:search] into
      # a search-results-list URL...
      link_back = link_back_to_catalog(opts).html_safe
      # ...but this can easily fail in multi-page web interactions, so catch errors
    rescue ActionController::RoutingError
      link_back = nil
    end

    # send back whatever we ended up with.
    link_back
  end

  # Local version of Blacklight::UrlHelperBehavior.link_to_document,
  # which preserves datasource within the route 
  def link_to_source_document(doc, opts = { label: nil, counter: nil, results_view: true, source: nil })
    label ||= blacklight_config.index.title_field.to_sym
    label = render_document_index_label doc, opts
    source = opts[:source] || @active_source

    url = "/#{source}/#{doc['id'].listify.first.to_s}"

    # BlackLight 5.2 updates how they track the counter, 
    # link_to label, url, :'data-counter' => options[:counter]
    link_to label, url, document_link_params(doc, opts)

  end

  def catalog_index_path(options = {})
    filtered_options = options.reject do |key, value|
      key.in?('controller', 'action', 'source_override')
    end
    source = options['source_override'] || @active_source

    "/#{source}?#{filtered_options.to_query}"
  end

  def render_document_index_label(doc, opts)
    label = nil
    label ||= doc.get(opts[:label]) if opts[:label].instance_of? Symbol
    label ||= opts[:label].call(doc, opts) if opts[:label].instance_of? Proc
    label ||= opts[:label] if opts[:label].is_a? String
    label ||= doc.get('id')
    label.listify.join(' ').to_s
  end

  def holdings_compact(document)
    online_holdings = format_online_results(online_link_hash(document))

    locations = document['location_call_number_id_display'].listify.reject do |loc|
      loc.match(/^Online/)
    end
    physical_holdings = format_brief_location_results(locations, document)

    all_holdings = online_holdings.concat(physical_holdings)

    # if all_holdings.size <= 3
    #   return all_holdings.join("\n<br>\n").html_safe
    # end

    # from display_helper, this conveniently lists all holdings if <= 3,
    # or 2 holdings plus a clickable "N more" label to display the rest
    convert_values_to_text(all_holdings, expand: true)
  end

  def per_page_link(href, per_page, current_per_page)
    label = "#{per_page} per page"

    if per_page == current_per_page
      checkmark = content_tag(:span, '', :class => 'glyphicon glyphicon-ok')
      content_tag(:a, (checkmark + ' ' + label), href: '#')
    else
      checkmark = content_tag(:span, '', :class => 'glyphicon glyphicon-spacer')
      content_tag(:a, (checkmark + ' ' + label), href: href, per_page: per_page, class: 'per_page_link')
    end
  end

  def catalog_per_page_link(per_page)
    current_per_page = @response.rows || 25

    # we need these to compute the correct new_page_number, below.
    current_page = [params_for_search[:page].to_i, 1].max
    first_record_on_page = (current_per_page * (current_page - 1)) + 1

    # do the math such that the current 1st item is still in the set
    new_page_number = (first_record_on_page / per_page).to_i + 1

    href = url_for(params_for_search.merge(rows: per_page, page: new_page_number))

    per_page_link(href, per_page, current_per_page)
  end

  def viewstyle_link(viewstyle, label)
    current_viewstyle = get_browser_option('viewstyle') ||
                        DATASOURCES_CONFIG['datasources'][@active_source]['default_viewstyle'] ||
                        'standard_list'

    # (support forward-conversion of renamed viewstyle names...)
    current_viewstyle = 'standard_list' if current_viewstyle == 'list'
    current_viewstyle = 'compact_list'  if current_viewstyle == 'compact'

    if viewstyle == current_viewstyle
      checkmark = content_tag(:span, '', :class => 'glyphicon glyphicon-ok')
      content_tag(:a, (checkmark + ' ' + label), href: '#')
    else
      checkmark = content_tag(:span, '', :class => 'glyphicon glyphicon-spacer')
      content_tag(:a, (checkmark + ' ' + label), href: '#', viewstyle: viewstyle, class: 'viewstyle_link')
    end
  end

  def database_link_label(links)
    label = 'Search Database:'
    if links and links.first and links.first[:url]
      content_tag(:a, label, href: links.first[:url], class: 'database_link')
    else
      content_tag(:span, label, class: 'database_link')
    end
  end

  def search_by_series_title(params)
    return false unless params.is_a?(Hash)

    # Basic Search
    return true if params.fetch('search_field', '') == 'series_title'

    # Advanced Search
    return true if params[:adv] && params[:adv].values.any?{ |adv_clause|
      adv_clause["field"] == "series_title"
    }

    return false
  end

end

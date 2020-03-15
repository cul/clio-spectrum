# encoding: UTF-8
#
module CulCatalogHelper
  def fix_catalog_links(text, source = active_source)
    text.to_s.gsub('/catalog', "/#{source}").html_safe
  end

  def build_link_back(_id = nil)
    # 1) EITHER start basic - just go back to where we came from... even if
    # it was a link found on a web page or in search-engine results...
    # link_back = request.referer.path
    # 2) OR have no "back" support unless the below works:
    link_back = nil

    begin

      # Jump to the current item within the search results?
      # No - because simple anchor behavior is to scroll so that
      # the anchor is top-most in viewport.  This means that
      # the search-box is always hidden, even for first document.
      # current_search_session.query_params.merge!(anchor: id)

      # add some extra info to the "Back to Results" link
      opts = { class: 'link_back' }

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
    # Rails.logger.debug "link_to_source_document() opts=[#{opts.inspect}]"
    blacklight_link = link_to_document(doc, opts[:label], counter: opts[:counter])
    source = opts[:source] || active_source
    fix_catalog_links(blacklight_link, source)
  end

  # def link_to_source_document(doc, opts = { label: nil, counter: nil, source: nil })
  #   label ||= blacklight_config.index.title_field.to_sym
  #   label = render_document_index_label doc, opts
  #   source = opts[:source] || active_source
  #   url = "/#{source}/#{doc['id'].listify.first.to_s}"
  #   link_to label, url, document_link_params(doc, opts)
  # end

  # WHY????
  # def catalog_index_path(options = {})
  #   filtered_options = options.reject do |key, value|
  #     key.in?('controller', 'action', 'source_override')
  #   end
  #   source = options['source_override'] || active_source
  #
  #   "/#{source}?#{filtered_options.to_query}"
  # end

  def render_document_index_label(doc, opts)
    label = nil
    label ||= doc.fetch(opts[:label]) if opts[:label].instance_of? Symbol
    label ||= opts[:label].call(doc, opts) if opts[:label].instance_of? Proc
    label ||= opts[:label] if opts[:label].is_a? String
    label ||= doc.fetch('id')
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
      checkmark = content_tag(:span, '', class: 'glyphicon glyphicon-ok')
      content_tag(:a, (checkmark + ' ' + label), href: '#')
    else
      checkmark = content_tag(:span, '', class: 'glyphicon glyphicon-spacer')
      content_tag(:a, (checkmark + ' ' + label), href: href, per_page: per_page, class: 'per_page_link')
    end
  end

  def catalog_per_page_link(per_page)
    current_per_page = @response.rows || 25

    # we need these to compute the correct new_page_number, below.
    current_page = [search_state.params_for_search[:page].to_i, 1].max
    first_record_on_page = (current_per_page * (current_page - 1)) + 1

    # do the math such that the current 1st item is still in the set
    new_page_number = (first_record_on_page / per_page).to_i + 1

    href = url_for(search_state.params_for_search.merge(rows: per_page, page: new_page_number))

    per_page_link(href, per_page, current_per_page)
  end

  def viewstyle_link(viewstyle, label)
    current_viewstyle = get_browser_option('viewstyle') ||
                        DATASOURCES_CONFIG['datasources'][active_source]['default_viewstyle'] ||
                        'standard_list'

    if viewstyle == current_viewstyle
      checkmark = content_tag(:span, '', class: 'glyphicon glyphicon-ok')
      content_tag(:a, (checkmark + ' ' + label), href: '#')
    else
      checkmark = content_tag(:span, '', class: 'glyphicon glyphicon-spacer')
      content_tag(:a, (checkmark + ' ' + label), href: '#', viewstyle: viewstyle, class: 'viewstyle_link')
    end
  end
  
  # def xls_form_link()
  #   url_for(search_state.params_for_search.merge(action: 'xls_form'))
  # end

  def xlsx_form_link()
    url_for(search_state.params_for_search.merge(action: 'xlsx_form'))
  end
  
  # link to either 
  def download_link(format)
    params = {
      format:     format,
      datasource: active_source,
      action:     'download'
    }
    url_for(search_state.params_for_search.merge(params))
  end
  
  def database_link_label(links)
    label = 'Search Database:'
    if links && links.first && links.first[:url]
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
    return false unless params.key?(:adv) and params[:adv].is_a?(Hash)
    return true if params[:adv].values.any? do |adv_clause|
      adv_clause.present? && adv_clause['field'] == 'series_title'
    end

    false
  end

  def law_requests_blurb
    text = 'Requests serviced by the '.html_safe
    link = link_to('Arthur W. Diamond Law Library', 'https://web.law.columbia.edu/library', target: '_blank')
    blurb = content_tag(:div, "#{text}<nobr>#{link}</nobr>".html_safe, class: 'service_menu_blurb')
  end

  def covid_19_blurb
    text = '<font color="darkred" weight="bold"><small>Interlibrary Loan, Borrow Direct, and Offsite ReCAP requests suspended until further notice.</small></font>'.html_safe
    # link = link_to('Read More...', 'https://library.columbia.edu/about/news/alert.html', target: '_blank')
    # blurb = content_tag(:div, "#{text}<nobr>#{link}</nobr>".html_safe, class: 'service_menu_blurb')
    blurb = content_tag(:div, "#{text}".html_safe, class: 'service_menu_blurb')
  end


  def get_badge_html(document)
    return nil unless document && document.id
    # begin
    badges = APP_CONFIG['badges']
    return nil unless badges && badges['bibs']
    # Lookup this doc to see if it's got a badge
    return nil unless badge_id = badges['bibs'][document.id.to_s]
    # use the badge id (e.g., "dcg") to fetch badge details
    badge = badges[badge_id]
    extra = { size: '50x80' }
    if badge['tooltip'].present?
      extra['data'] = { toggle: 'tooltip', placement: 'top' }
      extra['title'] = badge['tooltip']
    end
    badge_html = image_tag('icons/' + badge['icon'], extra)
    # rescue
    #   return nil
    # end
  end

end

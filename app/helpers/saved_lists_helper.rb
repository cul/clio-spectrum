module SavedListsHelper
  def get_full_url(list)
    root_url.sub(/\/$/, '') + list.url
  end

  def get_permissions_label(permissions)
    case permissions
    when 'private'
      html = "<span class='label label-info'>private</span>"
    when 'public'
      html = "<span class='label label-warning'>public</span>"
    else
      raise "get_permissions_label: unexpected value: #{permission}"
      end
    html.html_safe
  end
  
  def no_articles_blurb()
    
    icon = content_tag(:span, nil, class: 'glyphicon glyphicon-info-sign')
    
    zotero = link_to "Zotero", "https://library.columbia.edu/services/citation-management.html"
    
    message = "&nbsp; Articles+ content previously saved to CLIO Saved Lists is regrettably no longer available due to a vendor platform change. We recommend the use of third party citation management software such as <strong>#{zotero}</strong> as an alternative for those interested in managing non-Catalog citations."
    
    html = '<div class="alert alert-info" style="padding:6px">' + icon + message + '</div>'
    
    return html.html_safe
  end
  
end

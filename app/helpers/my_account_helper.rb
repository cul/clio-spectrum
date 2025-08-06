module MyAccountHelper
  
  # no more single-item renew get links - now it's checkboxes and post
  # def renew_link(loan)
  #   # To get newlines to show up in the pop-up confirmation
  #   # dialog, use hex codes + html_safe
  #   confirm_message = "Are you sure you want to renew the following item:   &#13;&#13;#{loan['item']['title']}"
  #   link_to "Renew", my_account_renew_path(loan_id: loan['id']), data: { confirm: confirm_message.html_safe }
  # end

  def cancel_link(request)
    # To get newlines to show up in the pop-up confirmation
    # dialog, use hex codes + html_safe
    confirm_message = "Are you sure you want to cancel your #{request['requestType']} for the following item:   &#13;&#13;#{request['instance']['title']}"
    link_to "Cancel", my_account_cancel_path(request_id: request['id']), data: { confirm: confirm_message.html_safe }
  end
  
  def user_display_name(folio_user)
    display_name = 'unknown'
    return display_name unless folio_user
    
    name_parts = Array.new()
    name_parts << (folio_user['personal']['firstName'] || '')
    name_parts << (folio_user['personal']['middleName'] || '')
    name_parts << (folio_user['personal']['lastName'] || '')
    name_parts << "(#{folio_user['username']})"
    display_name = name_parts.reject(&:empty?).join(' ')
  end
  
  def barcode_search_link(barcode)
    return '' unless barcode.present?
    # NEXT-1895 - "I’m going to ask that the clickable barcodes be turned off..."
    # link_to barcode, catalog_index_path(q: barcode)
    return barcode
  end
  
  

end



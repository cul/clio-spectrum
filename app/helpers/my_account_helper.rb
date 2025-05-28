module MyAccountHelper
  
  def renew_link(loan)
    # To get newlines to show up in the pop-up confirmation
    # dialog, use hex codes + html_safe
    confirm_message = "Are you sure you want to renew the following item:   &#13;&#13;#{loan['item']['title']}"
    link_to "Renew", my_account_renew_path(loan_id: loan['id']), data: { confirm: confirm_message.html_safe }
  end

  def cancel_link(request)
    # To get newlines to show up in the pop-up confirmation
    # dialog, use hex codes + html_safe
    confirm_message = "Are you sure you want to cancel your #{request['requestType']} for the following item:   &#13;&#13;#{request['instance']['title']}"
    link_to "Cancel", my_account_cancel_path(request_id: request['id']), data: { confirm: confirm_message.html_safe }
  end

end



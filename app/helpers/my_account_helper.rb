module MyAccountHelper
  
  def renew_link(loan)
    loan_id = loan['id']
    request = 'renew'
    # To get newlines to show up in the pop-up confirmation
    # dialog, use hex codes + html_safe
    confirm_message = "Are you sure you want to renew the following item:   &#13;&#13;#{loan['item']['title']}"
    link_to "Renew", new_my_account_path(loan_id: loan_id, request: request), data: { confirm: confirm_message.html_safe }
  end

  def cancel_link(loan)
    loan_id = loan['id']
    request = 'cancel'
    # To get newlines to show up in the pop-up confirmation
    # dialog, use hex codes + html_safe
    confirm_message = "Are you sure you want to cancel...:   &#13;&#13;#{loan['item']['title']}"
    link_to "Renew", new_my_account_path(loan_id: loan_id, request: request), data: { confirm: confirm_message.html_safe }
  end

end
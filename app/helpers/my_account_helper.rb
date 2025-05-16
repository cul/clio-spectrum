module MyAccountHelper
  
  def renew_link(loan)
    loan_id = loan['id']
    request = 'renew'
    link_to "Renew", new_my_account_path(loan_id: loan_id, request: request)
  end

end
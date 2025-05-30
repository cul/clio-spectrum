# 
# https://columbiauniversitylibraries.atlassian.net/browse/FOLIO-149
#
# Develop My Saved Lists, My Borrowing Account, My CLIO services for Folio catalog. 
# These may be grouped differently but essential services are:
#
# - items checked out “has list”
# - renew items
# - place hold/recall
# - saved lists
#
# What about?
# - seeing any fines
# - seeing any blocks
# 
class MyAccountController < ApplicationController
  # layout 'no_sidebar_no_search'
  layout 'no_sidebar'

  before_action :authenticate_user!

  def index
    @debug_mode = false   # debug is turned on somehow somewhere - disable for now

    # Fetch user details for the current user
    @user = Folio::Client.get_user_by_username(current_user.uid)
    user_id = @user['id']
    
    # But wait - are they trying to snoop on another user?
    if params[:uni]
      # snooping on themselves?  Why would they do this?
      return redirect_to my_account_index_path if params[:uni] == user_id
      # Only admins are allowed to snoop
      return redirect_to my_account_index_path unless current_user.admin?
      # OK, we have an approved snoop.
      # Try to retrieve the snoopee...
      @user = Folio::Client.get_user_by_username(params[:uni])
      return redirect_to my_account_index_path unless @user
      # It worked?  Ok, then proceed.
      @snooping = true
      user_id = @user['id']
    end

    @loans = Folio::Client.get_loans_by_user_id(user_id)
    @requests = Folio::Client.get_requests_by_user_id(user_id)
  end
  
  # # Any action, which makes "new" things happen, lands here
  # def new
  #   request    = my_account_params['request']
  #   loan_id    = my_account_params['loan_id']
  #   request_id = my_account_params['request_id']
  #
  #   # flash[:alert] = "alert"       # yellow
  #   # flash[:warning] = "warning"   # yellow
  #   # flash[:danger] = "danger"     # red
  #
  #   # What requests do we support?
  #   # unless ['renew', 'hold', 'recall'].include?(request)
  #   unless ['renew', 'recall', 'cancel'].include?(request)
  #     flash[:error] = "Unknown action: '#{request}'"
  #     redirect_to action: :index
  #     return
  #   end
  #
  #   return renew(loan_id) if request == 'renew'
  #   return renew(loan_id) if request == 'renew'
  #
  #   flash[:danger] = "failed to return from renew()"
  #   redirect_to action: :index
  # end
  
  

  def renew
    loan_id    = my_account_params['loan_id']

    begin
      loan = Folio::Client.folio_client.get("/circulation/loans/#{loan_id}")
    rescue => ex
      flash[:danger] = "Renewal Error:  #{ex.message}"
      redirect_to action: :index
      return
    end
    
    begin
      renewal = Folio::Client.renew_by_id(user_id: loan['userId'], item_id: loan['itemId'])
    rescue => ex
      flash[:danger] = "Renewal Error:  #{ex.message}"
      redirect_to action: :index
      return
    end
    
    flash[:success] = "Renew Successful for: #{loan['item']['title']}"
    redirect_to action: :index
  end



  def cancel
    request_id    = my_account_params['request_id']

    begin
      request = Folio::Client.folio_client.get("/circulation/requests/#{request_id}")
    rescue => ex
      flash[:danger] = "Error cancelling request:  #{ex.message}"
      redirect_to action: :index
      return
    end

    begin
      cancellation  = Folio::Client.delete_request(request_id: request_id)
    rescue => ex
      flash[:danger] = "Error cancelling request:  #{ex.message}"
      redirect_to action: :index
      return
    end
    
    flash[:success] = "Successfully cancelled your #{request['requestType']} for:  #{request['instance']['title']}."
    redirect_to action: :index
  end


  private

  def my_account_params
    params.permit(:user_id, :item_id, :loan_id, :request_id)
  end

  # Use something like this if we need to be more 
  # careful with the responses from the FOLIO API
  # def safe_json_parse(str)
  #   JSON.parse(str)
  # rescue JSON::ParserError
  #   nil
  # end
  
end






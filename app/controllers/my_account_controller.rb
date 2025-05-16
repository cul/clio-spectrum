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
    @debug_mode = false   # debug is turned on somehow somewhwere - disable for now
    
    @user = Folio::Client.get_user_by_username(current_user.uid)

    # hardcode for demonstration
    @user = Folio::Client.get_user_by_username( 'sam119' )

    user_id = @user['id']
    @loans = Folio::Client.get_loans_by_user_id(user_id)
    @requests = Folio::Client.get_requests_by_user_id(user_id)
  end
  
  # Any action, which makes "new" things happen, lands here
  def new
    loan_id = my_account_params['loan_id']
    request  = my_account_params['request']

    # flash[:alert] = "alert"       # yellow
    # flash[:warning] = "warning"   # yellow
    # flash[:danger] = "danger"     # red
    
    # What requests do we support?
    unless ['renew', 'hold', 'recall'].include?(request)
      flash[:error] = "Unknown action: '#{request}'"
      redirect_to action: :index
      return
    end

    # flash[:info] = "about to call renew()"
   
    return renew(loan_id) if request == 'renew'
    
    flash[:danger] = "failed to return from renew()"
    redirect_to action: :index
  end  
  
  
  private

  def my_account_params
    params.permit(:user_id, :item_id, :loan_id, :request)
  end

  def renew(loan_id)
    loan = Folio::Client.folio_client.get("/circulation/loans/#{loan_id}")
    user_id = loan['userId']
    item_id = loan['itemId']

    # It's important to keep these as string keys, not symbol keys,
    # or FolioClient will misinterpret them as keyword arguments
    params = { "itemId" => item_id, "userId" => user_id } 

    begin
      renewal_status = Folio::Client.folio_client.post(
        "/circulation/renew-by-id", 
         params
      )
    rescue FolioClient::ValidationError => ex
      message = ex.message
      message = message.sub(/There was a validation problem with the request: /, '')
      json = JSON.parse(message)
      if json and json["errors"]
        error_message = json["errors"].first["message"]
        flash[:danger] = "Renewal Error:  #{error_message}"
        return redirect_to action: :index
      end
    end

    redirect_to action: :index
  end

  def safe_json_parse(str)
    JSON.parse(str)
  rescue JSON::ParserError
    nil
  end
  
end






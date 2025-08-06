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
    params['list'] = 'loans'
    build_my_account_page(params)
  end
  
  def loans
    params['list'] = 'loans'
    build_my_account_page(params)
  end
  
  def requests
    params['list'] = 'requests'
    build_my_account_page(params)
  end


  # SINGLE ITEM GET RENEWAL - replaced by multi-item post renewal
  # def renew
  #   loan_id    = my_account_params['loan_id']
  #
  #   begin
  #     loan = Folio::Client.folio_client.get("/circulation/loans/#{loan_id}")
  #   rescue => ex
  #     flash[:danger] = "Renewal Error:  #{ex.message}"
  #     redirect_to action: :index
  #     return
  #   end
  #
  #   begin
  #     renewal = Folio::Client.renew_by_id(user_id: loan['userId'], item_id: loan['itemId'])
  #   rescue => ex
  #     flash[:danger] = "Renewal Error:  #{ex.message}"
  #     redirect_to action: :index
  #     return
  #   end
  #
  #   flash[:success] = "Renew Successful for: #{loan['item']['title']}"
  #   redirect_to action: :index
  # end


  def renew
    loan_ids = params[:loan_ids]

    if loan_ids.blank?
      flash[:warning] = "No items selected for renewal."
      redirect_to action: :index
      return
    end

    success_count = 0
    failure_count = 0
    error_messages = Set.new

    loan_ids.each do |loan_id|
      begin
        loan = Folio::Client.folio_client.get("/circulation/loans/#{loan_id}")
      rescue => ex
        Rails.logger.warn "Loan fetch failed for ID #{loan_id}: #{ex.message}"
        failure_count += 1
        error_messages << ex.message
        next
      end

      begin
        Folio::Client.renew_by_id(user_id: loan['userId'], item_id: loan['itemId'])
        success_count += 1
      rescue => ex
        Rails.logger.warn "Renewal failed for loan ID #{loan_id}: #{ex.message}"
        failure_count += 1
        error_messages << ex.message
      end
    end

    flash[:success] = "#{success_count} item#{'s' if success_count != 1} renewed successfully." if success_count > 0
    if failure_count > 0
      flash[:danger] = "#{failure_count} item#{'s' if failure_count != 1} failed to renew:\n" +
                       error_messages.to_a.join("\n")
    end
    

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

  def build_my_account_page(params)
    @debug_mode = false   # debug is turned on somehow somewhere - disable for now
 
    # Columbia ID system uni
    uni = current_user.uid
  
    # Fetch FOLIO user details for the current user
    @user = Folio::Client.get_user_by_username(uni)
    
    # FOLIO User UUID
    user_id = @user['id']
    
    # But wait - are they trying to snoop on another user?
    if params[:uni]
      # snooping on themselves?  Why would they do this?
      return redirect_to my_account_index_path if params[:uni] == uni
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
    
    # For the given FOLIO user_id (the current user, or a snooped-upon user),
    # fetch the data that we'll want to display...

    @loans = Folio::Client.get_loans_by_user_id(user_id)
    @requests = Folio::Client.get_requests_by_user_id(user_id)
    @blocks = Folio::Client.get_blocks_by_user_id(user_id)
    
    # default to displaying a list of loans, unless explicitly overridden
    @display_list = 'loans'
    @display_list = params['list'] if params['list']

    render :index
  end

    

  # Use something like this if we need to be more 
  # careful with the responses from the FOLIO API
  # def safe_json_parse(str)
  #   JSON.parse(str)
  # rescue JSON::ParserError
  #   nil
  # end
  
end






# 
# https://columbiauniversitylibraries.atlassian.net/browse/FOLIO-149
#
# Develop My Saved Lists, My Borrowing Account, My CLIO services for Folio catalog. 
# These may be grouped differently but essential services are:
#
# - items checked out “has list”
# - renew ites
# - place hold/recall
# - saved lists
#
class MyAccountController < ApplicationController
  layout 'no_sidebar_no_search'

  before_action :authenticate_user!

  def index
    @debug_mode = false   # debug is turned on somehow somewhwere - disable for now
    
    @user = Folio::Client.get_user_by_username(current_user.uid)

    # hardcode for demonstration
    # @user = Folio::Client.get_user_by_username( 'sam119' )

    user_uuid = @user['id']
    @loans = Folio::Client.get_loans_by_user_uuid(user_uuid)
    @requests = Folio::Client.get_requests_by_user_uuid(user_uuid)
  end
  
  
end

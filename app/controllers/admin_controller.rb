# The beginnings of an administrative interface for managing
# the Systems side of the application.
#
# 10/13 - this class is unused
#
class AdminController < ApplicationController
  layout 'no_sidebar'

  before_action :authenticate_user!, except: [:format_icons]

  def system
    redirect_to root_path unless current_user.has_role?('site', 'admin')
  end
  
  def request_services
    redirect_to root_path unless current_user && current_user.culstaff?
    
    @request_services = [
      # ### "Scan" Services ###
      'campus_scan',
      'recap_scan',
      'ill_scan',
      # ### "Pick-up" Services ###
      'campus_paging',
      'recap_loan',
      'borrow_direct',
      # ### Other Services ###
      'barnard_remote',
      'avery_onsite',
      'spec_coll',
    ]
    
    @all_locations = []
    @request_services.each do |service|
      @all_locations << APP_CONFIG["#{service}_locations"] 
    end
    @all_locations = @all_locations.compact.flatten.uniq.sort
    
    
  end


end



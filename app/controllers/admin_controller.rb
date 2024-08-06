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
    
    all_request_services = [
      # ### "Scan" Services ###
      'campus_scan',
      'recap_scan',
      'ill_scan',
      # ### "Pick-Up" Services ###
      'campus_paging',
      'fli_paging',
      'recap_loan',
      'borrow_direct',
      # ### Other Services ###
      'barnard_alum',
      'barnard_remote',
      'avery_onsite',
      'aeon',
      'microform',
      'starrstor'
    ]
    
    @all_locations = []
    @configured_services = []
    all_request_services.each do |service|
      location_list = SERVICE_LOCATIONS["#{service}_locations"] 
      if location_list.present?
        @configured_services << service
        @all_locations << location_list
      end
    end
    @all_locations = @all_locations.compact.flatten.uniq.sort
    
    
  end


end



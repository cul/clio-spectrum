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

end

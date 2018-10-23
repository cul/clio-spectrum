class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  include Cul::Omniauth::Callbacks

  def new_session_path(scope)
    new_user_session_path # this accomodates Users namespace of the controller
  end

  def affiliations(user, affils)
    return unless user
    user.affils = affils.sort
  end

end

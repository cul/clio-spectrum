# copied over from devise_wind
class SessionsController < Devise::SessionsController

  # CAS is ready.  No more wind.
  # ALL the below needs to be re-evaluated for CAS.
  # 
  # protect_from_forgery
  # 
  # def new
  #   create
  # end
  # 
  # def create
  #   expire_cache_for_user
  #   resource = warden.authenticate!(auth_options)
  #   set_flash_message(:notice, :signed_in) if is_navigational_format?
  #   # set_flash_message(:error, :logout_warning1) if is_navigational_format?
  #   # set_flash_message(:alert, :logout_warning2) if is_navigational_format?
  #   # set_flash_message(:success, :logout_warning3) if is_navigational_format?
  #   sign_in(resource_name, resource)
  #   redirect_to after_sign_in_path_for(resource)
  # end
  # 
  # def destroy
  #   expire_cache_for_user
  #   signed_in = signed_in?(resource_name)
  #   redirect_url = after_sign_out_path_for(resource_name) || root_url
  # 
  #   if redirect_url.match(/^\/$/)
  #     redirect_url = root_url
  #   end
  #   Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
  #   set_flash_message :notice, :signed_out if signed_in
  # 
  #   # We actually need to hardcode this as Rails default responder doesn't
  #   # support returning empty response on GET request
  #   respond_to do |format|
  #     format.any(*navigational_formats) { redirect_to "https://#{User.wind_host}/logout?passthrough=1&destination=" + redirect_url }
  #     format.all do
  #         method = "to_#{request_format}"
  #         text = {}.respond_to?(method) ? {}.send(method) : ''
  #         render text: text, status: :ok
  #       end
  #   end
  # end

  private

  def expire_cache_for_user
    expire_fragment("top_navigation_bar_#{current_user}") if current_user
  end
end

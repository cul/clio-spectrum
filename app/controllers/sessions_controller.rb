# copied over from devise_wind
class SessionsController < Devise::SessionsController
	protect_from_forgery
	def new
		create
	end
	
	def create
	  resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    redirect_to after_sign_in_path_for(resource)
    expire_cache_for_user
  end

	def destroy
		signed_in = signed_in?(resource_name)
		redirect_url = after_sign_out_path_for(resource_name) || root_url

		if redirect_url.match(/^\/$/)
			redirect_url = root_url
		end
		Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
		set_flash_message :notice, :signed_out if signed_in
    expire_cache_for_user

		# We actually need to hardcode this as Rails default responder doesn't
		# support returning empty response on GET request
		respond_to do |format|
    	format.any(*navigational_formats) { redirect_to "https://#{User.wind_host}/logout?passthrough=1&destination=" + redirect_url }
			format.all do
		    	method = "to_#{request_format}"
		    	text = {}.respond_to?(method) ? {}.send(method) : ""
		    	render :text => text, :status => :ok
		  	end
		end
	end

  private

  def expire_cache_for_user
    expire_fragment('top_navigation_bar')
  end
	
end


RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller
end

# based on
# http://rawlins.weboffins.com/2013/03/22/request-and-controller-specs-with-devise/

# This module authenticates users for request specs.#
module ValidUserRequestHelper
    # Define a method which signs in as a valid user.
    def login(user)
      # sign_in, sign_out are provided by Devise::TestHelpers, to 
      # give you a session without navigating through the app's
      # login screens.
      sign_out :user
      sign_in :user, user
    end

    def logout
      sign_out :user
    end
end

RSpec.configure do |config|
    config.include ValidUserRequestHelper
end

# Better, simpler advice:
#    https://github.com/plataformatec/devise/wiki/How-To:-Test-with-Capybara

include Warden::Test::Helpers
Warden.test_mode!

RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
end

# Use these in Capybara Feature specs

def feature_login(user)
  feature_logout
  login_as user, scope: :user
  user
end

def feature_logout
  logout :user
end

# Use these in other specs (Controller, etc.)

def spec_login(user)
  spec_logout
  sign_in :user, user
  user
end

def spec_logout
  sign_out :user
end

#
# # based on
# # http://rawlins.weboffins.com/2013/03/22/request-and-controller-specs-with-devise/
#
# # This module authenticates users for request specs.#
# module ValidUserRequestHelper
#     # Define a method which signs in as a valid user.
#     def login(user)
#       # sign_in, sign_out are provided by Devise::TestHelpers, to
#       # give you a session without navigating through the app's
#       # login screens.
#       sign_out :user
#       sign_in :user, user
#     end
#
#     def logout
#       sign_out :user
#     end
# end
#
# RSpec.configure do |config|
#     config.include ValidUserRequestHelper
# end
#
#
# # http://www.clevertakes.com/blog/2013/01/30/how-do-i-add-devise-login-method-to-my-rspec-feature-test/
# include Warden::Test::Helpers
#
# module FeatureHelpers
#
#   def feature_login(user)
#     login_as user, scope: :user
#     user
#   end
#
# end
#
# RSpec.configure do |config|
#   config.include FeatureHelpers, type: :feature
# end

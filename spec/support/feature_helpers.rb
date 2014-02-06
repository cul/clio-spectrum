# 
# # http://www.clevertakes.com/blog/2013/01/30/how-do-i-add-devise-login-method-to-my-rspec-feature-test/
# include Warden::Test::Helpers
# 
# module FeatureHelpers
# 
#   def login(user)
#     login_as user, scope: :user
#     user
#   end
# 
# end
# 
# RSpec.configure do |config|
#   config.include FeatureHelpers, type: :feature
# end

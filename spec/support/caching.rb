
# This was an attempt to fix a problem with testing email...
#   undefined method `perform_caching' for #<RecordMailer:0x0000010b33a840>
# but it had no effect.

# 
# # Toggle caching on/off via a ":caching => true" key attached to each spec test
# #   http://rosskaff.com/blog/2011/12/toggle-rails-caching-in-rspec-suite.html
# 
# 
# 
# RSpec.configure do |config|
# 
#   # set as part of Spork, but include here as well
#   config.treat_symbols_as_metadata_keys_with_true_values = true
# 
#   config.around(:each, :caching) do |example|
#     caching = ActionController::Base.perform_caching
#     ActionController::Base.perform_caching = example.metadata[:caching]
#     example.run
#     ActionController::Base.perform_caching = caching
#   end
# end
# 
# 
# # config.action_controller.perform_caching = true

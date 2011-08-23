# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] ||= "cucumber"

require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'

# Comment out the next line if you don't want Cucumber Unicode support
require 'cucumber/formatter/unicode'

# Comment out the next line if you don't want transactions to
# open/roll back around each scenario
#Cucumber::Rails.use_transactional_fixtures

# Comment out the next line if you want Rails' own error handling
# (e.g. rescue_action_in_public / rescue_responses / rescue_from)
#Cucumber::Rails.bypass_rescue

require 'cucumber/rails/rspec'

Capybara.run_server = true #Whether start server when testing
Capybara.default_selector = :xpath #default selector , you can change to :css
Capybara.default_wait_time = 2 #When we testing AJAX, we can set a default wait time
Capybara.ignore_hidden_elements = false #Ignore hidden elements when testing, make helpful when you hide or show elements using javascript
Capybara.javascript_driver = :culerity #default driver when you using @javascript tag


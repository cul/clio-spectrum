




guard 'spork',:rspec_env => { 'RAILS_ENV' => 'test' } do
  watch('config/application.rb')
  watch('config/environment.rb')
  watch('config/environments/test.rb')
  watch(%r{^config/initializers/.+\.rb$})
  watch('Gemfile')
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb') { :rspec }
  watch('test/test_helper.rb') { :test_unit }
end


# 10/2014 - NEW guard rspec clause, as found in https://github.com/guard/guard-rspec

guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

# OLD guard rspec clause - it's been there forever, untouched.

# guard 'rspec', :cli => "--drb --format progress ", :all_after_pass => false do
# 
#   # Capybara request specs
#   watch(%r{^app/views/(.+)/.*\.(erb|haml)$})          { |m| "spec/requests/#{m[1]}_spec.rb" }
#   watch(%r{^spec/.+_spec\.rb$})
#   watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
#   watch('spec/spec_helper.rb')  { "spec" }
# 
#   # Rails example
#   watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
#   watch(%r{^app/(.*)(\.erb|\.haml)$})                 { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
#   watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
#   watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
#   watch('config/routes.rb')                           { "spec/routing" }
#   watch('app/controllers/application_controller.rb')  { "spec/controllers" }
# 
# end



## Sample template for guard-unicorn
#
# Usage:
#     guard :unicorn, <options hash>
#
# Possible options:
# * :daemonize (default is true) - should the Unicorn server start daemonized?
# * :config_file (default is "config/unicorn.rb") - the path to the unicorn file
# * :pid_file (default is "tmp/pids/unicorn.pid") - the path to the unicorn pid file

guard 'rails', :port => 3030 do
  watch('Gemfile.lock')
  watch('tmp/restart.txt')
  watch(%r{^(config|lib)/.*})
end


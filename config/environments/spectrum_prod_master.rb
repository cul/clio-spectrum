# minimal configuration settings necessary
# for cron jobs against master solr index
Clio::Application.configure do
  # Silence the noisy deprecations,
  # we don't need them in our cron email output
  ActiveSupport::Deprecation.silenced = true
end

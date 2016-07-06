# following example from:
#   https://relishapp.com/vcr/vcr/v/2-9-3/docs/getting-started
require 'vcr'

VCR.configure do |c|

  ## VCR on/off toggle
  ## Do this, and VCR is enacted on specs tagged with :vcr
  ## Comment this out to test directly against live backends
  c.configure_rspec_metadata!

  c.cassette_library_dir = 'vcr/cassettes'
  c.hook_into :webmock

  # VCR will ignore HTTP requests unless excplitly called
  c.allow_http_connections_when_no_cassette = true

  # Tell VCR not to pay attention to any localhost connection,
  #   (like Capybara's JS-related calls to /__identify__)
  c.ignore_localhost = true

  # The acquisition-date facet options are computed based on current date.
  #   e.g., facet.query=acq_dt:[2014-09-21T00:00:00Z TO *]
  # Ignore all facet.query params - is this the only one?
  c.default_cassette_options = {
    # Un-comment this line to trigger re-recording of ALL cassettes
    # :re_record_interval => 1.days,
    :match_requests_on => [:method,
      VCR.request_matchers.uri_without_param('facet.query')]
  }

  # Don't put URLs in the cassettes, so they can go into public repo
  # https://relishapp.com/vcr/vcr/v/2-5-0/docs/configuration/filter-sensitive-data
  # http://stackoverflow.com/questions/9816152
  c.filter_sensitive_data("<ac2_solr_url>") { APP_CONFIG['ac2_solr_url'] }
  c.filter_sensitive_data("<library_api_path>") { APP_CONFIG['library_api_path'] }
  c.filter_sensitive_data("<clio_backend_url>") { APP_CONFIG['clio_backend_url'] }
  c.filter_sensitive_data("<solr_config>") { SOLR_CONFIG['test']['url'] }


  # Not working?  Use this to spew debugging to console
  # c.debug_logger = $stdout


end

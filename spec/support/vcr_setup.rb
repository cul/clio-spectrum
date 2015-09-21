# following example from:
#   https://relishapp.com/vcr/vcr/v/2-9-3/docs/getting-started
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'vcr/cassettes'
  c.hook_into :webmock

  # VCR will ignore HTTP requests unless excplitly called
  c.allow_http_connections_when_no_cassette = true

  # Tell VCR not to pay attention to any localhost connection,
  #   (like Capybara's JS-related calls to /__identify__)
  c.ignore_localhost = true

  # Do this, and VCR is only enacted on specs tagged with :vcr
  c.configure_rspec_metadata!

  # The acquisition-date facet options are computed based on current date.
  #   e.g., facet.query=acq_dt:[2014-09-21T00:00:00Z TO *]
  # Ignore all facet.query params - is this the only one?
  c.default_cassette_options = {
    :match_requests_on => [:method,
      VCR.request_matchers.uri_without_param('facet.query')]
  }

  # Not working?  Use this to spew debugging to console
  # c.debug_logger = $stdout


end

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

  # Not working?  Use this to spew debugging to console
  # c.debug_logger = $stdout


end

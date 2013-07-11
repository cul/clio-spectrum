# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Clio::Application.initialize!

# re-patch logger to restore format patched out by Rails
class Logger
  def format_message(severity, timestamp, program, message)
    "#{timestamp.to_formatted_s(:db)} [#{severity}] #{message}\n"
  end
end

require 'rails'
require 'clicktale/engine'
require 'clicktale/controller'

module Clicktale
  CONFIG = HashWithIndifferentAccess.new
  begin
    # conffile = File.join(Rails.root.to_s + "/config/clicktale.yml")
    conffile = File.join(File.dirname(__FILE__)  + '/../config/clicktale.yml')
    conf = YAML.load(File.read(conffile))

    CONFIG.merge!(conf[Rails.env]) if conf[Rails.env]
  rescue
    puts '*' * 50
    puts "#{conffile} can not be loaded:"
    puts $ERROR_INFO
    puts '*' * 50
  end
end

require 'rails'

# require 'action_controller'
# require 'action_view'

require 'clicktale/controller'
require 'clicktale/helper'


module Clicktale
  class Engine < ::Rails::Engine

    initializer 'extend ActionController, ActionView' do |app|
      # puts '=========== BBB'
      # Rails.logger.debug "==== initializer"

      ActionController::Base.send(:include, Clicktale::Controller)
      ActionView::Base.send(:include, Clicktale::Helper)

    end

  end
end

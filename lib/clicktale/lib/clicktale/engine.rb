require 'rails'

require 'clicktale/controller'
require 'clicktale/helper'

module Clicktale
  class Engine < ::Rails::Engine

    initializer 'extend ActionController, ActionView' do |app|
      ActionController::Base.send(:include, Clicktale::Controller)
      ActionView::Base.send(:include, Clicktale::Helper)
    end

  end
end

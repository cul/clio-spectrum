require 'rails'
require 'clicktale/controller'

module Clicktale
  class Engine < ::Rails::Engine
    initializer 'extend ActionController, ActionView' do |app|
      ActionController::Base.send(:include, Clicktale::Controller)
    end
  end
end

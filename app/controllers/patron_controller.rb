class PatronController < ApplicationController
  include Blacklight::Catalog


  before_filter :by_source_config
  before_filter :authenticate_user!
  layout 'no_sidebar'

  def index
    @voyager_connection = Voyager::Connection.new(APP_CONFIG['voyager_connection'])
    @patron = Voyager::Patron.new(uni: current_user.login, connection: @voyager_connection)



  end
end

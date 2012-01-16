class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 
  before_filter :determine_active_source

  
  def determine_active_source
    @active_source = case request.path 
    when /^\/databases/
      'Databases'
    when /^\/new_arrivals/
      'New Arrivals'
    when /^\/catalog/
      'Catalog'
    when /^\/articles/
      'Articles'
    when /^\/ebooks/
      'eBooks'
    when /^\/academic_commons/
      'Academic Commons'
    else
      params['active_source'] || 'Quicksearch'
    end
  end


  def current_user


  end


end


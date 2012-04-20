require 'blacklight/catalog'

class LibraryWebController < ApplicationController
  layout "quicksearch"
  
  include Blacklight::Catalog

  def index
    session['search'] = params
    if params['q']
      @results = LibraryWeb::Api.new(params)
    end
  end
end

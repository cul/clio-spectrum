require 'blacklight/catalog'

class LibraryWebController < ApplicationController
  layout "quicksearch"
  
  include Blacklight::Catalog

  def index
    if params['q']
      @results = LibraryWeb::API.new(params)
    end
  end
end

require 'blacklight/catalog'

class ArticlesController < ApplicationController
  include Blacklight::Catalog
  

  def search
    @search = if (category = params.delete('new_search'))
      SerialSolutions::SummonAPI.search_new(category, params)
    else
      SerialSolutions::SummonAPI.search(params)
    end
      
  end
  

  def show
    @document = SerialSolutions::Link360.new(params[:openurl])

    render "show", :layout => "no_sidebar"
  end

end

require 'blacklight/catalog'

class ArticlesController < ApplicationController
  include Blacklight::Catalog
  layout "articles"


  def search
    params.reverse_merge!( :refine_search => 'new', :category => 'articles' )
    category = params.delete(:category)
    @search = if (params.delete(:refine_search) == 'new')
    
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

require 'blacklight/catalog'

class ArticlesController < ApplicationController
  layout "articles"


  def index
    @new_search = true
    @summon = SerialSolutions::SummonAPI.new('new_search' => true, 'category' => 'articles')
    
  end
  def search
    @new_search = !params.has_key?('category') || (params['new_search'] && params['new_search'] != '')
    
    @summon = SerialSolutions::SummonAPI.new(params)
  end
  

  def show
    @document = SerialSolutions::Link360.new(params[:openurl])

    render "show", :layout => "no_sidebar"
  end

end

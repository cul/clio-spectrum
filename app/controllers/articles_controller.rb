require 'blacklight/catalog'

class ArticlesController < ApplicationController
  include Blacklight::Catalog
  layout "articles"


  def search
    params = {:new_search => true, :category => 'articles'} if params.empty?
    @summon = SerialSolutions::SummonAPI.new(params)
  end
  

  def show
    @document = SerialSolutions::Link360.new(params[:openurl])

    render "show", :layout => "no_sidebar"
  end

end

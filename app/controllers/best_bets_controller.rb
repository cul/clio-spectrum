class BestBetsController < ApplicationController

  def index
    q = params['q']

    if ActiveRecord::Base.connection.adapter_name.match /sqlite/i
      wildcard = '%' + q.gsub(/ +/, '%') + '%'
      @hits = BestBets.where('title LIKE ?', wildcard)
    end

    if ActiveRecord::Base.connection.adapter_name.match /mysql/i
      @hits = BestBets.where('match(title,url,description) against (?)', q)
    end

  end
  
end

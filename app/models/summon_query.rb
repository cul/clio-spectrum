class SummonQuery
  include Rails.application.routes.url_helpers
  Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options

  attr_reader :query

  def initialize(s)
    @query = params

  end

  def previous_page
    new_page = [@query['s.pn'].to_i - 1, 1].max
    articles_search_path(@query.merge('s.pn' => new_page))
  end

  def next_page
    new_page = [@query['s.pn'].to_i - 1, 1].max
    articles_search_path(@query.merge('s.pn' => new_page))
  end



end

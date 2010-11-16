module GoogleBooks
  def self.retrieve_book_info(isbns)
    results = []

    http_client_with_cookies do |hc|

    end

  end

  private

  def self.http_client_with_cookies
    hc = HTTPClient.new
    hc.set_cookie_store(COOKIE_STORE)
    yield hc
    hc.cookie_manager.save_all_cookies(true)
  end


end



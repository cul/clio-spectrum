# marquis, 5/2013 - this seems like dead code
#
# module GoogleBooks
#   GOOGLE_BOOKS_URL = "http://books.google.com/books?jscmd=viewapi&bibkeys="
#   COOKIE_STORE = Rails.root.to_s + "/tmp/cookies/holding_cookies.dat"
#
#   def self.retrieve_book_info(*documents)
#     results = {}
#     isbns = documents.collect { |d| d["isbn_display"] }.compact.flatten.uniq
#
#     retrieve_url = GOOGLE_BOOKS_URL + isbns.join(",")
#
#     begin
#       http_client_with_cookies do |hc|
#         var_gbs = hc.get_content(retrieve_url).gsub("var _GBSBookInfo = ","").gsub(/;$/,"")
#
#
#         api_results = JSON.parse(var_gbs)
#
#         documents.each do |document|
#           document["isbn_display"].listify.each do |isbn|
#             if api_results[isbn]
#               results[document] = api_results[isbn]
#               break
#             end
#           end
#         end
#
#       end
#     rescue
#     end
#
#     return results
#   end
#
#   private
#
#   def self.http_client_with_cookies
#     hc = HTTPClient.new
#     hc.set_cookie_store(COOKIE_STORE)
#     yield hc
#     hc.cookie_manager.save_all_cookies(true)
#   end
#
#
# end
#
#

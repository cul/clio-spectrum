json.extract! best_bet, :id, :title, :description, :keywords, :url
# json.url best_bet_url(best_bet, format: :json)

json.haystack [best_bet.title, best_bet.description, best_bet.keywords].join(' ')


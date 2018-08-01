json.extract! best_bet, :id, :title, :description, :keywords, :url
# json.url best_bet_url(best_bet, format: :json)

json.haystack [best_bet.title, best_bet.description, best_bet.keywords].join(' ')

# Turn CSV keywords into space-less tokens
# (works together with "concatter" custom typeahead tokenizer)
json.token best_bet.keywords.gsub(/ /,'').gsub(/,/, ' ')


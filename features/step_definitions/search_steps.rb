
require 'uri'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

When /^(?:|I )search (?:|the )(.+) for "([^"]*)"$/ do |source, query| 
  case source
  when "catalog"
    visit catalog_index_path(:q => query)
  when "databases"
    visit databases_index_path(:q => query)
  when "quicksearch"
    visit root_path(:q => query)
  when "ebooks"
    visit ebooks_index_path(:q => query)
  when "new_arrivals", "new arrivals"
    visit new_arrivals_index_path(:q => query)
  when "articles"
    visit articles_index_path(:q => query)
  end
end

When /^I click on the "([^"]*)" result$/  do |id|
  input_id = id.to_i - 1
  results = all('.result')
  if results[input_id]
    results[input_id].click
  else
    raise "Result #{id} out of #{results.length} not found"
  end
end


def click_on_result(id)

end

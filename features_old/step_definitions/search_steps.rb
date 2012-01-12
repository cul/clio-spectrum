
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

When /^I click on the first result$/  do
  raise page.html.to_s.inspect
  find('.result').click
end

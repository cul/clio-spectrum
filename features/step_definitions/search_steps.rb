
require 'uri'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

When /^(?:|I )search (?:|the )"([^"]*)" for "([^"]*)"$/ do |source, query| 
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
    visit articles_search_path('s.q' => query)
  end
end

When /^I click on the "(\d*)[^"]*" result$/  do |id|
  find_result(id).find('.title a').click
end

When /^looking at the "(\d*)[^"]*" result$/ do |id|
  @active_result = find_result(id)
end

Then /^the title should include "([^"]*)"$/ do |title|
  assert @active_result.find('.title a').text.include?(title)
end

Then /^the "([^"]*)" field should include "([^"]*)"$/ do |field, value|
  found = false

  @active_result.all('.row').each do |row|
    if row.find('.label').text == field
      found = true
      assert row.all('.entry').any? { |entry| entry.text.include?(value) }, "Field found, but #{value} was not in value."
    end
  end

  assert found, "Row with field name #{field} not found"
end

Then /^the link should be local$/ do 
  href = @active_result.find('.title a')['href']
  assert href =~ /^\//, "#{href} not local"
end

Then /^the link should not be local$/ do 
  href = @active_result.find('.title a')['href']
  assert !(href =~ /^\//), "#{href} is local"
end

def find_result(id)
  return find(".result:nth-of-type(#{id.to_i})")
end



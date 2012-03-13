
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
    visit articles_search_path('s.q' => query, 'new_search' => true)
  end
end

When /^I click on the "(\d*)[^"]*" result$/  do |id|
  find_result(id).find('.title a').click
end

When /^looking at the "(\d*)[^"]*" result$/ do |id|
  @active_result = find_result(id)
end

When /^I look at the item level view$/ do
  @active_result = page.find('.item_show')
end

Then /^the title should include "([^"]*)"$/ do |title|
  found_title = @active_result.find('.title a').text
  assert found_title.downcase.include?(title.to_s.downcase), "Title #{found_title} does not include #{title}"
end

Then /^the "([^"]*)" field should include "([^"]*)"$/ do |field, value|
  found = false

  if active_field = find_field(@active_result,field)
    entries = active_field.all('.entry').collect(&:text)
    assert entries.any? { |entry| entry.downcase.include?(value.to_s.downcase) }, "Field found, but #{value} was not in #{entries.inspect}"
  else
    raise "Row with field name #{field} not found"
  end
end



Then /^the link should be local$/ do 
  href = @active_result.find('.title a')['href']
  assert href =~ /^\//, "#{href} not local"
end

Then /^the link should not be local$/ do 
  href = @active_result.find('.title a')['href']
  assert !(href =~ /^\//), "#{href} is local"
end

And /^the holdings have the database "([^"]*)" with links "([^"]*)"$/ do |database, link_text|
  links = link_text.split(",").collect(&:strip)
  holdings = @active_result.all(".holding")

  holding = holdings.detect { |h| h.find(".resource_box").text.include?(database) }
  
  assert holding, "Database #{database} not found in holding."

  holding_links = holding.all(".links a").collect { |node| node.text.strip }
  holding_links.should include(*links)


end

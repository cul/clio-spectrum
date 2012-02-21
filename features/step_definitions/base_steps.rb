
require 'uri'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

Then /^the path should include "([^"]+)"$/ do |path_snippet|
  current_path = URI.parse(current_url).path
  assert current_path.include?(path_snippet)
end

Then /^(?:|I )should be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).path
  if current_path.respond_to? :should  
    current_path.should == path_to(page_name)  
  else  
    assert_equal path_to(page_name), current_path  
  end  
end

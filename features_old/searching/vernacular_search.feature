@searching
Feature: Vernacular Scripts and Searching (Stanford)
  In order to get fantastic search results for vernacular queries
  As an end user, when I enter vernacular search terms
  I want to see search results with awesome relevancy, recall, precision
  
Scenario: Cyrillic
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "пушкин pushkin"
  And I select "Title" from "search_field"
  And I press "search"
  And I select "50" from "per_page"
  And I press "per_page_submit"
  Then I should get at least 12 results
  And I should get ckey 216398 in the results
  And I should get ckey 7898778 in the results
  And I should get ckey 7898632 in the results
  And I should get ckey 7773771 in the results
  And I should get ckey 7640577 in the results
  And I should get ckey 7834141 in the results
  And I should get ckey 7829897 in the results
  And I should get ckey 7654022 in the results
  And I should get ckey 4543433 in the results
  And I should get ckey 2972618 in the results
  And I should get ckey 2785723 in the results
  And I should get ckey 2349714 in the results
  And I should get ckey 7755391 in the results
  # from 490  
  And I should get ckey 3420269 in the results
  


# TODO: chinese / japanese / korean:  multiple scripts

# TODO: right-to-left scripts

# TODO:  vernacular with and without diacritics (greek, hebrew, arabic)

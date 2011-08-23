@searching
Feature: Searching non-alphabetic characters  (Stanford)
  In order to get correct search results for words with non-alphabetic characters
  As an end user, when I enter search terms with or without non-alphabetic characters
  I want to see comprehensible search results with awesome relevancy, recall, precision  
 
Scenario: brackets as part of a search should be ignored
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "mark twain [pseud]" 
  And I press "search"
  Then I should get at least 125 total results
  And I should get the same number of results as a search for "mark twain pseud"

Scenario: brackets as part of a phrase search should be ignored
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in the search box with "\"mark twain [pseud]\""
  And I press "search"
  Then I should get at least 125 total results
  And I should get the same number of results as a search for "\"mark twain pseud\""
  
Scenario: Period at end of term is ignored
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "Nature."
  And I select "Title" from "search_field"
  And I press "search"
  Then I should get ckey 1337040 in the results
  # Journal:  7917346, 3195844  Other books:  581294, 1361438
  And I should get the same number of results as a title search for "Nature"
  
Scenario: Leading ellipsis is ignored
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "...Nature"
  And I select "Title" from "search_field"
  And I press "search"
  Then I should get ckey 1361438 in the results
  And I should get the same number of results as a title search for "Nature"

Scenario: Trailing ellipsis is ignored
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "I want..."
  And I select "Title" from "search_field"
  And I press "search"
  Then I should get ckey 7490934 in the results
  And I should get the same number of results as a title search for "I want"
  # TODO:  but  "I want ..."  with the space gives ZERO results 
  #   HOWEVER:  it is the same as the others in VuFind

Scenario: Slash surrounded by spaces in alpha search
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "Physical chemistry / Ira N Levine"
  And I press "search"
  Then I should get at least 4 of these ckeys in the first 5 results: "1726910, 3016212, 4712578, 7633476"

Scenario: Numbers (and slash), no letters:  56 1/2
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "56 1/2"
  And I press "search"
  Then I should get ckey 6031340 in the first 3 results
  And I should get ckey 5491883 in the first 3 results
  
Scenario: Numbers (and slash), no letters:  33 1/3
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "33 1/3"
  And I select "Title" from "search_field"
  And I press "search"
  And I select "title" from "sort"
  And I press "sort_submit"
  # Socrates gets 71 titles;  Blacklight gets 59 titles;  Vufind 44 as of 2009-05-06
  Then I should get at least 50 total results
  And I should get ckey 6721172 in the first 3 results

# TODO: can't parse this stuff with double quotes
#Scenario: Search for unmatched double quote as part of query
#  Given a SOLR index with Stanford MARC data
#  And I go to the home page
#  When I fill in "q" with "\"space traveler"
#  And I press "search"
#  Then I should get results
#  And I should get the same number of results as a search for "space traveler"
#  And I should get the same number of results as a search for "space" traveler"
#  And I should get the same number of results as a search for "space "traveler"
#  And I should get the same number of results as a search for "space " traveler"
#  And I should get the same number of results as a search for "space traveler""

Scenario: Search for unmatched single quote as part of query
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "'space traveler"
  And I press "search"
  Then I should get results
  And I should get the same number of results as a search for "space traveler"
  And I should get the same number of results as a search for "space' traveler"
  And I should get the same number of results as a search for "space 'traveler"
  And I should get the same number of results as a search for "space traveler'"
  # single quote on its lonesome doesn't work
  #  And I should get the same number of results as a search for "space ' traveler"

Scenario: Search for unmatched bracket as part of query
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "[wise up"
  And I press "search"
  Then I should get results
  And I should get the same number of results as a search for "wise up"
  And I should get the same number of results as a search for "wise[ up"
  And I should get the same number of results as a search for "wise [up"
  And I should get the same number of results as a search for "wise up["
  And I should get the same number of results as a search for "]wise up"
  And I should get the same number of results as a search for "wise] up"
  And I should get the same number of results as a search for "wise ]up"
  And I should get the same number of results as a search for "wise up]"

Scenario: Search for unmatched curly brace in query
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "{final chord"
  And I press "search"
  Then I should get results
  And I should get the same number of results as a search for "final chord"
  And I should get the same number of results as a search for "final{ chord"
  And I should get the same number of results as a search for "final {chord"
  And I should get the same number of results as a search for "final chord{"
  And I should get the same number of results as a search for "}final chord"
  And I should get the same number of results as a search for "final} chord"
  And I should get the same number of results as a search for "final }chord"
  And I should get the same number of results as a search for "final chord}"


Scenario: Punctuation as part of a phrase should be ignored
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in the search box with "\"Alice in Wonderland : a serie[s]\""
  And I press "search"
  Then I should get at least 2 results
  And I should get the same number of results as a search for "\"Alice in Wonderland a serie[s]\""


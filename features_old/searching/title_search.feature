@searching
Feature: Title Search Result Relevancy (Stanford)
  In order to get fantastic title search results
  As an end user, when I do title searches
  I want to see search results with awesome relevancy, recall, precision
  
# $ is truncation symbol for Socrates, which doesn't stem
Scenario: Results for "byzantine figur$" should >= Socrates result quality
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "byzantine figur$"
  And I select "Title" from "search_field"
  And I press "search"
  # these four have (stemmed) byzantine figure in the title
  Then I should get at least 4 of these ckeys in the first 4 results: "2440554, 3013697, 1498432, 5165378"
  # 7769264: title has only byzantine; 505t has "figural"
  And I should get ckey 5165378 before ckey 7769264
  And I should get ckey 1498432 before ckey 7769264
  # 7096823 has "Byzantine" "figurine" in separate 505t subfields.  
#   apparently "figurine" does not stem to the same word as "figure"
#    And I should get ckey 7096823 in the results
  
Scenario: japanese journal of applied physics - 780t, 785t indexed
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "japanese journal of applied physics"
  And I select "Title" from "search_field"
  And I press "search"
  Then I should get at least 7 of these ckeys in the first 8 results: "365562, 491322, 491323, 7519522, 7519487, 460630, 787934"
  When I follow "Journal/Periodical"
  Then I should get at least 5 of these ckeys in the first 5 results: "7519522, 365562, 491322, 491323, 7519522"

Scenario: japanese journal of applied physics PAPERS - 780t, 785t indexed
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "japanese journal of applied physics papers"
  And I select "Title" from "search_field"
  And I press "search"
  Then I should get at least 7 of these ckeys in the first 8 results: "365562, 491322, 491323, 7519522, 7519487, 460630, 787934"
  When I follow "Journal/Periodical"
  Then I should get at least 5 of these ckeys in the first 5 results: "7519522, 365562, 491322, 491323, 7519522"

Scenario: japanese journal of applied physics LETTERS - 780t, 785t indexed
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "japanese journal of applied physics letters"
  And I select "Title" from "search_field"
  And I press "search"
  Then I should get at least 7 of these ckeys in the first 8 results: "365562, 8207522, 491322, 491323, 7519522, 7519487, 460630"
  When I follow "Journal/Periodical"
  Then I should get at least 5 of these ckeys in the first 5 results: "365562, 8207522, 491322, 491323, 7519522"

Scenario: journal of marine biotechnology - 780t, 785t indexed
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "journal of marine biotechnology"
  And I select "Title" from "search_field"
  And I press "search"
  Then I should get at least 3 of these ckeys in the first 3 results: "4450293, 1963062, 4278409"
  When I follow "Journal/Periodical"
  Then I should get at least 3 of these ckeys in the first 3 results: "4450293, 1963062, 4278409"


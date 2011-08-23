@searching
Feature: Stopwords should not interfere with search results (Stanford)
  In order to get fantastic search results
  As an end user, when I enter stopwords in search terms
  I want to see results with awesome relevancy, recall, precision

Scenario: Stopwords in title searches should be ignored - 3 words total
  Given I am on the home page
  When I fill in "q" with "alice in wonderland"
  And I select "Title" from "search_field"
  And I press "search"
  Then I should get at least 100 total results
  And I should get the same number of results as a title search for "alice wonderland"
  And I should get more results than a title search for "\"alice in wonderland\""

Scenario: Stopwords ("of") in everything searches should be ignored - 4 words total
  Given I am on the home page
  When I fill in "q" with "forgotten shipbuilders of belfast"
  And I press "search"
  Then I should get ckey 5954022 in the first 1 result
  And I should get the same number of results as a search for "forgotten shipbuilders belfast"

Scenario: Stopwords ("in") in everything searches should be ignored - 4 words total
  Given I am on the home page
  When I fill in "q" with "race relations in literature"
  And I press "search"
  Then I should get at least 160 total results
  And I should get the same number of results as a search for "race relations literature"
  And I should get more results than a search for "\"Race relations in literature.\""

Scenario: Stopwords ("in the") in everything searches should be ignored - 3 words total
  Given I am on the home page
  When I fill in "q" with "bats in the belfry"
  And I press "search"
  Then I should get results
  And I should get the same number of results as a search for "bats belfry"

Scenario: Stopwords ("of) in title searches should be ignored - 4 words total
  Given I am on the home page
  When I fill in "q" with "forgotten shipbuilders of belfast"
  And I select "Title" from "search_field"
  And I press "search"
  Then I should get ckey 5954022 in the first 1 result
  And I should get the same number of results as a title search for "forgotten shipbuilders belfast"
  
Scenario: Stopwords in author searches should be ignored
  Given I am on the home page
  When I fill in "q" with "king of scotland"
  And I select "Author" from "search_field"
  And I press "search"
  Then I should get at least 20 total results
  And I should get the same number of results as an author search for "king scotland"
  And I should get more results than an author search for "\"king of scotland\""

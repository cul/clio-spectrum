@searching @punctuation
Feature: Search Queries Containing SEMICOLONS  (Stanford)
  In order to get correct search results for queries containing semicolons
  As an end user, when I enter a search query with semicolons
  I want to see comprehensible search results with awesome relevancy, recall, precision  
 
  Scenario: Space separated SEMICOLON in query should not affect results
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Lecture notes in statistics ;"
    And I press "search"
    And I should get the same number of results as a search for "Lecture notes in statistics"

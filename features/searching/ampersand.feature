@searching @punctuation
Feature: Search Queries Containing AMPERSANDS (&)  (Columbia)
  In order to get correct search results for queries containing ampersands
  As an end user, when I enter a search query with ampersands
  I want to see comprehensible search results with awesome relevancy, recall, precision  
 
  Scenario: 2 term query with AMPERSAND, 0 Stopwords  (VUF-831)
    Given a SOLR index with Columbia MARC data
    And I go to the catalog page
    When I fill in "q" with "Bandits & Bureaucrats"
    And I press "search"
    #Then I should get at least 5 results
    #And I should get ckey 2972993 in the first 1 results
    #And I should get the same number of results as a search for "Bandits Bureaucrats"
    #And I should get more results than a search for "\"Bandits Bureaucrats\""

@searching @punctuation @hyphen @fixme
Feature: Search Queries Containing Hyphens - Odd Cases (Stanford)
  In order to get correct search results for queries containing hyphens
  As an end user, when I enter a search query with hyphens 
  I want to see comprehensible search results with awesome relevancy, recall, precision  
 
  Scenario: result has HYPHEN surrounded by spaces
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "The John - Donkey"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "8166294, 365685"

  Scenario: result has HYPHEN surrounded by spaces, PHRASE
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"The John - Donkey\""
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "8166294, 365685"

  Scenario: result has HYPHEN surrounded by spaces, TITLE
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "The John - Donkey"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "8166294, 365685"

  Scenario: result has HYPHEN surrounded by spaces, TITLE, PHRASE
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"The John - Donkey\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "8166294, 365685"



  Scenario: result has HYPHEN surrounded by spaces, 1 add'l term (VUF-803)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "Deutsch - Sudwestafrikanische Zeitung"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "410366, 8230044"

  Scenario: result has HYPHEN surrounded by spaces, 1 add'l term, PHRASE (VUF-803)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Deutsch - Sudwestafrikanische Zeitung\""
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "410366, 8230044"

  Scenario: result has HYPHEN surrounded by spaces, 1 add'l term, TITLE (VUF-803)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Deutsch - Sudwestafrikanische Zeitung"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "410366, 8230044"

  Scenario: result has HYPHEN surrounded by spaces, 1 add'l term, TITLE, PHRASE (VUF-803)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Deutsch - Sudwestafrikanische Zeitung\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "410366, 8230044"




  Scenario: result has multiple HYPHENs - treat as phrase
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "probabilities for use in stop-or-go sampling"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "2146380, 3336158"
    And I should get the same number of results as a search for "probabilities for use in \"stop or go\" sampling"
    
  Scenario: result has multiple HYPHENs, TITLE - treat as phrase
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "probabilities for use in stop-or-go sampling"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "2146380, 3336158"
    And I should get the same number of results as a title search for "probabilities for use in \"stop or go\" sampling"



  Scenario: COLON and HYPHEN
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Silence : a thirteenth-century French romance"
    And I press "search"
    Then I should get ckey 2416395 in the first 1 results
    And I should get the same number of results as a search for "Silence : a \"thirteenth century\" French romance"
    And I should get the same number of results as a search for "Silence a \"thirteenth century\" French romance"
  
  Scenario: COLON and HYPHEN, TITLE
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Silence : a thirteenth-century French romance"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2416395 in the first 1 result
    And I should get the same number of results as a title search for "Silence : a \"thirteenth century\" French romance"
    And I should get the same number of results as a title search for "Silence a \"thirteenth century\" French romance"
  


  Scenario: Result has hyphenated word surrounded by quotes
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Color-blind\" racism"
    And I press "search"
    Then I should get ckey 3499287 in the first 1 result
    And I should get the same number of results as a search for "\"Color blind\" racism"

  Scenario: COLON and HYPHEN, TITLE
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Color-blind\" racism"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 3499287 in the first 1 result
    And I should get the same number of results as a title search for "\"Color blind\" racism"

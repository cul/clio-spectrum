@searching
Feature: Boolean Operators (Stanford)
  In order to get fantastic search results
  As an end user, when I do searching with boolean terms or corresponding symbols
  I want to see search results that reflect the boolean query appropriately

  Scenario: default operator --> AND (everything search)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "horn"
    And I press "search"
    Then I should get more results than a search for "french horn"

  Scenario: default operator --> AND (everything search)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "loggerhead turtles"
    And I press "search"
    # this was in the facets when default was "OR"
    Then I should not see "Shakespeare"

  Scenario: default operator --> AND (author search)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "michaels"
    And I select "Author" from "search_field"
    And I press "search"
    Then I should get more results than a search for "leonard michaels"

  Scenario: default operator --> AND (title search)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "turtles"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get more results than a search for "sea turtles"
    
  Scenario: default operator --> AND  across MARC fields
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "gulko sea turtles"
    And I press "search"
    Then I should get at most 1 result
    And I should get ckey 5958831 in the results
  
  Scenario: NOT operator 
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "wb4 NOT shakespeare"
    And I press "search"
    Then I should not get ckey 1989093 in the results
    And I should get the same number of results as a search for "wb4 -shakespeare"
    And I should get fewer results as a search for "wb4"

  Scenario: NOT operator 
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "cats NOT poets"
    And I press "search"
    Then I should not get ckey 5373870 in the results
    And I should get the same number of results as a search for "cats -poets"
    And I should get fewer results than a search for "cats"
  
  Scenario: NOT same as hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "twain NOT sawyer"
    And I press "search"
    And I should get the same number of results as a search for "twain -sawyer"
    And I should get fewer results than a search for "twain"
    
  Scenario: Stopword in Query Ignored:  lower case and
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Catholic thought and papal jury policy"
    And I press "search"
    Then I should get ckey 1711043 in the results

  Scenario: Hyphen Between Two Letters Ignored
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "South Africa, Shakespeare and post-colonial culture"
    And I press "search"
    Then I should get results

  
  
@searching
Feature: mm setting for dismax (Stanford)
  As a user
  I want to be able to use long multi-word queries
  In order to get great results which may not contain all the words in my queries

  # see also:  boolean features (these queries with and, AND)
  
  Scenario: South Africa, Shakespeare post-colonial culture (hyphen but no "and")
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "South Africa, Shakespeare post-colonial culture"
    And I press "search"
    Then I should get results

  Scenario: South Africa, Shakespeare postcolonial culture (neither hyphen nor "and")
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "South Africa, Shakespeare postcolonial culture"
    And I press "search"
    Then I should get results
  
  Scenario: South Africa, Shakespeare post colonial culture ("post" separate word, no "and")
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "South Africa, Shakespeare post colonial culture"
    And I press "search"
    Then I should get results
  
  # "South Africa" Shakespeare post colonial culture
  #   can't do partial phrase query

  Scenario: Catholic thought papal jury policy (no "and")
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Catholic thought papal jury policy"
    And I press "search"
    Then I should get ckey 1711043 in the results
  
  
  
  
  
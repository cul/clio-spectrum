@searching @punctuation @hyphen @fixme
Feature: Search Queries Containing Hyphens With Space After But Not Before (Stanford)
  In order to get correct search results for queries containing hyphens
  As an end user, when I enter a search query with hyphens with a space after but not before
  I want to see comprehensible search results with awesome relevancy, recall, precision  
 
  Scenario: HYPHEN with space after but not before, 0 add'l terms: ignore hyphen (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "neo- romantic"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 10 results: "1665493, 2775888"
    And I should get the same number of results as a search for "neo romantic"
    And I should get more results than a search for "\"neo romantic\""

  Scenario: HYPHEN with space after but not before, 0 add'l terms, in a PHRASE: ignore hyphen (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"neo- romantic\""
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 10 results: "1665493, 2775888"
    And I should get the same number of results as a search for "\"neo romantic\""

  Scenario: HYPHEN with space after but not before, TITLE search, 0 add'l terms: ignore hyphen (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "neo- romantic"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 10 results: "1665493, 2775888"
    And I should get the same number of results as a title search for "neo romantic"
    And I should get more results than a title search for "\"neo romantic\""

  Scenario: HYPHEN with space after but not before, TITLE search, 0 add'l terms, in a PHRASE: ignore hyphen (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"neo- romantic\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 10 results: "1665493, 2775888"
    And I should get the same number of results as a title search for "\"neo romantic\""



  Scenario: HYPHEN with space after but not before, 1 stopword, 1 add'l term: ignore hyphen (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "under the sea- wind"
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "5621261, 545419, 2167813"
    And I should get the same number of results as a search for "under the sea wind"
    And I should get more results than a search for "\"under the sea wind\""

  Scenario: HYPHEN with space after but not before, in a PHRASE, 1 stopword, 1 add'l term: ignore hyphen (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"under the sea- wind\""
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "5621261, 545419, 2167813"
    And I should get the same number of results as a search for "\"under the sea wind\""
    
  Scenario: HYPHEN with space after but not before, TITLE search, 1 stopword, 1 add'l term: ignore hyphen (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "under the sea- wind"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "5621261, 545419, 2167813"
    And I should get the same number of results as a title search for "under the sea wind"
    And I should get more results than a title search for "\"under the sea wind\""

  Scenario: HYPHEN with space after but not before, TITLE search, in a PHRASE, 1 stopword, 1 add'l term: ignore hyphen (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"under the sea- wind\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "5621261, 545419, 2167813"
    And I should get the same number of results as a title search for "\"under the sea wind\""


  Scenario: HYPHEN with space after but not before, 2 add'l terms, 0 stopwords: ignore hyphen (SW-288)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "customer- driven academic library"
    And I press "search"
    Then I should get ckey 7778647 in the results
    And I should get the same number of results as a search for "customer driven academic library"
    And I should get more results than a search for "\"customer driven academic library\""

  Scenario: HYPHEN with space after but not before, in a PHRASE, 2 add'l terms, 0 stopwords: ignore hyphen (SW-288)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"customer- driven academic library\""
    And I press "search"
    Then I should get ckey 7778647 in the results
    And I should get the same number of results as a search for "\"customer driven academic library\""

  Scenario: HYPHEN with space after but not before, TITLE search, 2 add'l terms, 0 stopwords: ignore hyphen (VUF-846)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "customer- driven academic library"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7778647 in the results
    And I should get the same number of results as a title search for "customer driven academic library"

  Scenario: HYPHEN with space after but not before, TITLE search, in a PHRASE, 2 add'l terms, 0 stopwords: ignore hyphen (VUF-846)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"customer- driven academic library\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7778647 in the results
    And I should get the same number of results as a title search for "\"customer driven academic library\""

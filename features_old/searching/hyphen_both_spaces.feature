@searching @punctuation @hyphen @fixme
Feature: Search Queries Containing Hyphens Surrounded by Spaces (Stanford)
  In order to get correct search results for queries containing hyphens
  As an end user, when I enter a search query with hyphens surrounded by spaces
  I want to see comprehensible search results with awesome relevancy, recall, precision  
 
  Scenario: HYPHEN with spaces before and after, 0 add'l terms: ignore hyphen (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "neo - romantic"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 10 results: "1665493, 2775888"
    And I should get the same number of results as a search for "neo romantic"
    And I should get more results than a search for "\"neo romantic\""

  Scenario: HYPHEN with spaces before and after, 0 add'l terms, in a PHRASE: ignore hyphen (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"neo - romantic\""
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 10 results: "1665493, 2775888"
    And I should get the same number of results as a search for "\"neo romantic\""


  Scenario: HYPHEN within numbers, spaces before and after: ignore hyphen
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "1951 - 1960"
    And I press "search"
    Then I should get ckey 7477647 in the results
    And I should get the same number of results as a search for "1951 1960"
    And I should get more results than a search for "\"1951 1960\""

  Scenario: HYPHEN within numbers, spaces before and after, in a PHRASE: ignore hyphen
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"1951 - 1960\""
    And I press "search"
    Then I should get ckey 7477647 in the results
    And I should get the same number of results as a search for "\"1951 1960\""


  Scenario: HYPHEN with spaces before and after, 1 add'l term: ignore hyphen (VUF-803)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Deutsch - Sudwestafrikanische Zeitung"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "410366, 8230044"
    And I should get the same number of results as a search for "Deutsch Sudwestafrikanische Zeitung"
    And I should get more results than a search for "\"Deutsch Sudwestafrikanische Zeitung\""

  Scenario: HYPHEN with spaces before and after, in a PHRASE, 1 add'l term: ignore hyphen (VUF-803)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Deutsch - Sudwestafrikanische Zeitung\""
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "410366, 8230044"
    And I should get the same number of results as a search for "\"Deutsch Sudwestafrikanische Zeitung\""


  Scenario: HYPHEN with spaces before and after, 1 stopword, 1 add'l term: ignore hyphen (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "under the sea - wind"
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "5621261, 545419, 2167813"
    And I should get the same number of results as a search for "under the sea wind"
    And I should get more results than a search for "\"under the sea wind\""

  Scenario: HYPHEN with spaces before and after, in a PHRASE, 1 stopword, 1 add'l term: ignore hyphen (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"under the sea - wind\""
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "5621261, 545419, 2167813"
    And I should get the same number of results as a search for "\"under the sea wind\""


  Scenario: HYPHEN with spaces before and after, 2 add'l terms, 1 stopword: ignore hyphen (VUF-846)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "catalogue of high - energy accelerators"
    And I press "search"
    Then I should get ckey 1156871 in the results
    And I should get the same number of results as a search for "catalogue of high energy accelerators"
    And I should get more results than a search for "\"catalogue of high energy accelerators\""

  Scenario: HYPHEN with spaces before and after, in a PHRASE, 2 add'l terms, 1 stopword: ignore hyphen (VUF-846)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"catalogue of high - energy accelerators\""
    And I press "search"
    Then I should get ckey 1156871 in the results
    And I should get the same number of results as a search for "\"catalogue of high energy accelerators\""


  Scenario: HYPHEN with spaces before and after, 3 add'l terms, 0 stopwords: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Mid - term fiscal policy review"
    And I press "search"
    Then I should get ckey 7204125 in the results
    And I should get the same number of results as a search for "Mid term fiscal policy review" 
    And I should get more results than a search for "\"Mid term fiscal policy review\""

  Scenario: HYPHEN with spaces before and after, in a PHRASE, 3 add'l terms, 0 stopwords: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Mid-term fiscal policy review\""
    And I press "search"
    Then I should get ckey 7204125 in the results
    And I should get the same number of results as a search for "\"Mid term fiscal policy review\""


  Scenario: HYPHEN with spaces before and after, 3 add'l terms, 1 stopword: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "The third plan mid - term appraisal"
    And I press "search"
    Then I should get ckey 2234698 in the results
    And I should get the same number of results as a search for "The third plan mid term appraisal"
    And I should get more results than a search for "\"The third plan mid term appraisal\""

  Scenario: HYPHEN with spaces before and after, in a PHRASE, 3 add'l terms, 1 stopword: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"The third plan mid - term appraisal\""
    And I press "search"
    Then I should get ckey 2234698 in the results
    And I should get the same number of results as a search for "\"The third plan mid term appraisal\""


  Scenario: HYPHEN with spaces before and after, 6 add'l terms, 1 stopword: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Color - blindness [print/digital]; its dangers and its detection"
    And I press "search"
    Then I should get ckey 7778647 in the results
    And I should get the same number of results as a search for "Color blindness [print/digital]; its dangers and its detection"
    And I should get more results than a search for "\"Color blindness [print/digital]; its dangers and its detection\""

  Scenario: HYPHEN with spaces before and after, in a PHRASE, 6 add'l terms, 1 stopword: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Color - blindness [print/digital]; its dangers and its detection\""
    And I press "search"
    Then I should get ckey 7778647 in the results
    And I should get the same number of results as a search for "\"Color blindness [print/digital]; its dangers and its detection\""



  Scenario: HYPHEN with spaces before and after, TITLE search, 0 add'l terms: ignore hyphen (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "neo - romantic"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 10 results: "1665493, 2775888"
    And I should get the same number of results as a title search for "neo romantic"
    And I should get more results than a title search for "\"neo romantic\""

  Scenario: HYPHEN with spaces before and after, TITLE search, 0 add'l terms, in a PHRASE: ignore hyphen (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"neo - romantic\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 10 results: "1665493, 2775888"
    And I should get the same number of results as a title search for "\"neo romantic\""


  Scenario: HYPHEN within numbers, spaces before and after, TITLE search: ignore hyphen
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "1951 - 1960"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7477647 in the results
    And I should get the same number of results as a title search for "1951 1960"
    And I should get more results than a title search for "\"1951 1960\""

  Scenario: HYPHEN within numbers, spaces before and after, TITLE search, in a PHRASE: ignore hyphen
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"1951 - 1960\"" 
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7477647 in the results
    And I should get the same number of results as a title search for "\"1951 1960\"" 


  Scenario: HYPHEN with spaces before and after, TITLE search, 1 add'l term: ignore hyphen (VUF-803)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Deutsch - Sudwestafrikanische Zeitung"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "410366, 8230044"
    And I should get the same number of results as a title search for "Deutsch Sudwestafrikanische Zeitung"
    And I should get more results than a title search for "\"Deutsch Sudwestafrikanische Zeitung\""

  Scenario: HYPHEN with spaces before and after, TITLE search, in a PHRASE, 1 add'l term: ignore hyphen (VUF-803)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Deutsch - Sudwestafrikanische Zeitung\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "410366, 8230044"
    And I should get the same number of results as a title search for "\"Deutsch Sudwestafrikanische Zeitung\""


  Scenario: HYPHEN with spaces before and after, TITLE search, 1 stopword, 1 add'l term: ignore hyphen (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "under the sea - wind"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "5621261, 545419, 2167813"
    And I should get the same number of results as a title search for "under the sea wind"
    And I should get more results than a title search for "\"under the sea wind\""

  Scenario: HYPHEN with spaces before and after, TITLE search, in a PHRASE, 1 stopword, 1 add'l term: ignore hyphen (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"under the sea - wind\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "5621261, 545419, 2167813"
    And I should get the same number of results as a title search for "\"under the sea wind\""


  Scenario: HYPHEN with spaces before and after, TITLE search, 2 add'l terms, 1 stopword: ignore hyphen (VUF-846)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "catalogue of high - energy accelerators"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 1156871 in the results
    And I should get the same number of results as a title search for "catalogue of high energy accelerators"
    And I should get more results than a title search for "\"catalogue of high energy accelerators\""

  Scenario: HYPHEN with spaces before and after, TITLE search, in a PHRASE, 2 add'l terms, 1 stopword: ignore hyphen (VUF-846)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"catalogue of high - energy accelerators\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 1156871 in the results
    And I should get the same number of results as a title search for "\"catalogue of high energy accelerators\""


  Scenario: HYPHEN with spaces before and after, TITLE search, 3 add'l terms, 0 stopwords: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Mid - term fiscal policy review"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7204125 in the results
    And I should get the same number of results as a title search for "Mid term fiscal policy review" 
    And I should get more results than a title search for "\"Mid term fiscal policy review\""

  Scenario: HYPHEN with spaces before and after, TITLE search, in a PHRASE, 3 add'l terms, 0 stopwords: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Mid-term fiscal policy review\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7204125 in the results
    And I should get the same number of results as a title search for "\"Mid term fiscal policy review\""


  Scenario: HYPHEN with spaces before and after, TITLE search, 3 add'l terms, 1 stopword: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "The third plan mid - term appraisal"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2234698 in the results
    And I should get the same number of results as a title search for "The third plan mid term appraisal"
    And I should get more results than a title search for "\"The third plan mid term appraisal\""

  Scenario: HYPHEN with spaces before and after, TITLE search, in a PHRASE, 3 add'l terms, 1 stopword: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"The third plan mid - term appraisal\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2234698 in the results
    And I should get the same number of results as a title search for "\"The third plan mid term appraisal\""


  Scenario: HYPHEN with spaces before and after, TITLE search, 6 add'l terms, 1 stopword: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Color - blindness [print/digital]; its dangers and its detection"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7778647 in the results
    And I should get the same number of results as a title search for "Color blindness [print/digital]; its dangers and its detection"
    And I should get more results than a title search for "\"Color blindness [print/digital]; its dangers and its detection\""

  Scenario: HYPHEN with spaces before and after, TITLE search, in a PHRASE, 6 add'l terms, 1 stopword: ignore hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Color - blindness [print/digital]; its dangers and its detection\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7778647 in the results
    And I should get the same number of results as a title search for "\"Color blindness [print/digital]; its dangers and its detection\""



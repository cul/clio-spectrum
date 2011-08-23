@searching @punctuation @hyphen @fixme
Feature: Search Queries Containing Hyphens With Space Before But Not After (treat as NOT) (Stanford)
  In order to get correct search results for queries containing hyphens
  As an end user, when I enter a search query with hyphens with a space before but not after
  I want to see comprehensible search results with awesome relevancy, recall, precision  
 
  Scenario: HYPHEN space before but not after, 0 add'l terms: treat hyphen as NOT (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "neo -romantic"
    And I press "search"
    Then I should NOT get ckey 2095712 in the results
    And I should get ckey 445186 in the results
    And I should get the same number of results as a search for "neo NOT romantic"
    And I should get fewer results than a search for "neo"

  Scenario: HYPHEN space before but not after in PHRASE, 0 add'l terms: ignore Hyphen (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"neo -romantic\""
    And I press "search"
    Then I should get ckey 2095712 in the results
    And I should get the same number of results as a search for "\"neo romantic\""

  Scenario: HYPHEN space before but not after, TITLE search, 0 add'l terms: treat hyphen as NOT (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "neo -romantic"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should NOT get ckey 2095712 in the results
    And I should get ckey 445186 in the results
    And I should get the same number of results as a title search for "neo NOT romantic"
    And I should get fewer results than a title search for "neo"

  Scenario: HYPHEN space before but not after, TITLE search, in PHRASE, 0 add'l terms: ignore Hyphen (VUF-798)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"neo -romantic\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2095712 in the results
    And I should get the same number of results as a title search for "\"neo romantic\""



  Scenario: HYPHEN within numbers, space before but not after: treat hyphen as NOT
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "1951 -1960"
    And I press "search"
    Then I should NOT get ckey 7477647 in the results
    And I should get ckey 4332587 in the results
    And I should get the same number of results as a search for "1951 NOT 1960"
    And I should get fewer results than a search for "1951"
        
  Scenario: HYPHEN within numbers, space before but not after in PHRASE: ignore Hyphen 
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"1951 -1960\""
    And I press "search"
    Then I should get ckey 7477647 in the results
    And I should get the same number of results as a search for "\"1951 1960\""

  Scenario: HYPHEN within numbers, space before but not after, TITLE search: treat hyphen as NOT
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "1951 -1960"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should NOT get ckey 7477647 in the results
    And I should get ckey 4332587 in the results
    And I should get the same number of results as a title search for "1951 NOT 1960"
    And I should get fewer results than a title search for "1951"

  Scenario: HYPHEN within numbers, space before but not after, TITLE search, in PHRASE,: ignore Hyphen 
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"1951 -1960\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7477647 in the results
    And I should get the same number of results as a title search for "\"1951 1960\""
    
    
    
  Scenario: HYPHEN space before but not after, 1 add'l term: treat hyphen as NOT (VUF-803)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Deutsch -Sudwestafrikanische Zeitung"
    And I press "search"
    Then I should NOT get ckey 410366 in the results
    And I should get ckey 425291 in the results
    And I should get the same number of results as a search for "Deutsch NOT Sudwestafrikanische Zeitung" 
    And I should get the same number of results as a search for "Deutsch Zeitung NOT Sudwestafrikanische" 
    And I should get fewer results than a search for "Deutsch Zeitung"
    
  Scenario: HYPHEN space before but not after in PHRASE, 1 add'l term: ignore Hyphen (VUF-803)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Deutsch -Sudwestafrikanische Zeitung\""
    And I press "search"
    Then I should get ckey 410366 in the results
    And I should get the same number of results as a search for "\"Deutsch Sudwestafrikanische Zeitung\""

  Scenario: HYPHEN space before but not after, TITLE search, 1 add'l term: treat hyphen as NOT (VUF-803)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Deutsch -Sudwestafrikanische Zeitung"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should NOT get ckey 410366 in the results
    And I should get ckey 425291 in the results
    And I should get the same number of results as a title search for "Deutsch NOT Sudwestafrikanische Zeitung"
    And I should get fewer results than a title search for "Deutsch Zeitung"

  Scenario: HYPHEN space before but not after, TITLE search, in PHRASE, 1 add'l term: ignore Hyphen (VUF-803)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Deutsch -Sudwestafrikanische Zeitung\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 410366 in the results
    And I should get the same number of results as a title search for "\"Deutsch Sudwestafrikanische Zeitung\""



  Scenario: HYPHEN space before but not after, 1 stopword, 1 add'l term: treat hyphen as NOT (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "under the sea -wind"
    And I press "search"
    Then I should NOT get ckey 5621261 in the results
    And I should NOT get ckey 545419 in the results
    And I should NOT get ckey 2167813 in the results
    And I should get ckey 8652881 in the results
    And I should get the same number of results as a search for "under the sea NOT wind"
    And I should get fewer results than a search for "under the sea"
        
  Scenario: HYPHEN space before but not after in PHRASE, 1 stopword, 1 add'l term: ignore Hyphen (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"under the sea -wind\""
    And I press "search"
    Then I should get ckey 5621261 in the results
    And I should get ckey 545419 in the results
    And I should get ckey 2167813 in the results
    And I should get the same number of results as a search for "\"under the sea wind\""

  Scenario: HYPHEN space before but not after, TITLE search, 1 stopword, 1 add'l term: treat hyphen as NOT (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "under the sea -wind"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should NOT get ckey 5621261 in the results
    And I should NOT get ckey 545419 in the results
    And I should NOT get ckey 2167813 in the results
    And I should get ckey 8652881 in the results
    And I should get the same number of results as a title search for "under the sea NOT wind"
    And I should get fewer results than a title search for "under the sea"

  Scenario: HYPHEN space before but not after, TITLE search, in PHRASE, 1 stopword, 1 add'l term: ignore Hyphen (VUF-966)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"under the sea -wind\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 5621261 in the results
    And I should get ckey 545419 in the results
    And I should get ckey 2167813 in the results
    And I should get the same number of results as a title search for "\"under the sea wind\""



  Scenario: HYPHEN space before but not after, 2 add'l terms: treat hyphen as NOT (VUF-846)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "customer -driven academic library"
    And I press "search"
    Then I should NOT get ckey 7778647 in the results
    And I should get the same number of results as a search for "customer NOT driven academic library"
    And I should get the same number of results as a search for "customer academic library NOT driven"
    And I should get fewer results than a search for "customer academic library" 

  Scenario: HYPHEN space before but not after in PHRASE, 2 add'l terms: ignore Hyphen (VUF-846)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"customer -driven academic library\""
    And I press "search"
    Then I should get ckey 7778647 in the results
    And I should get the same number of results as a search for "\"customer driven academic library\""

  Scenario: HYPHEN space before but not after, TITLE search, 2 add'l terms: treat hyphen as NOT (VUF-846)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "customer -driven academic library"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should NOT get ckey 7778647 in the results
    And I should get the same number of results as a title search for "customer NOT driven academic library"
    And I should get the same number of results as a title search for "customer academic library NOT driven"
    And I should get fewer results than a title search for "customer academic library"

  Scenario: HYPHEN space before but not after, TITLE search, in PHRASE, 2 add'l terms: ignore Hyphen (VUF-846)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"customer -driven academic library\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7778647 in the results
    And I should get the same number of results as a title search for "\"customer driven academic library\""



  Scenario: HYPHEN space before but not after, 3 add'l terms, 0 stopwords: treat hyphen as NOT
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Mid -term fiscal policy review"
    And I press "search"
    Then I should NOT get ckey 7204125 in the results
    And I should get ckey 8489935 in the results
    And I should get the same number of results as a search for "Mid NOT term fiscal policy review"
    And I should get the same number of results as a search for "Mid fiscal policy review NOT term"
    And I should get fewer results than a search for "Mid fiscal policy review"

  Scenario: HYPHEN space before but not after in PHRASE, 3 add'l terms, 0 stopwords: ignore Hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Mid -term fiscal policy review\""
    And I press "search"
    Then I should get ckey 7204125 in the results
    And I should get the same number of results as a search for "\"Mid term fiscal policy review\""

  Scenario: HYPHEN space before but not after, TITLE search, 3 add'l terms, 0 stopwords: treat hyphen as NOT 
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Mid -term fiscal policy review"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should NOT get ckey 7204125 in the results
    And I should get ckey 8489935 in the results
    And I should get the same number of results as a title search for "Mid NOT term fiscal policy review"
    And I should get the same number of results as a title search for "Mid fiscal policy review NOT term"
    And I should get fewer results than a title search for "Mid fiscal policy review"

  Scenario: HYPHEN space before but not after, TITLE search, in PHRASE, 3 add'l terms, 0 stopwords: ignore Hyphen
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Mid -term fiscal policy review\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 7204125 in the results
    And I should get the same number of results as a title search for "\"Mid term fiscal policy review\""


  Scenario: HYPHEN space before but not after, 3 add'l terms, 2 stopwords: treat hyphen as NOT
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "beyond race in a race -obsessed world"
    And I press "search"
    Then I should NOT get ckey 3381968 in the results
    And I should get ckey 3148369 in the results
    And I should get the same number of results as a search for "beyond race in a race NOT obsessed world"
    And I should get the same number of results as a search for "beyond race in a race world NOT obsessed" 
    And I should get fewer results than a search for "beyond race in a race world"

  Scenario: HYPHEN space before but not after in PHRASE, 3 add'l terms, 2 stopwords: ignore Hyphen 
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"beyond race in a race -obsessed world\""
    And I press "search"
    Then I should get ckey 3381968 in the results
    And I should get the same number of results as a search for "\"beyond race in a race obsessed world\""

  Scenario: HYPHEN space before but not after, TITLE search, 3 add'l terms, 2 stopwords: treat hyphen as NOT 
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "beyond race in a race -obsessed world"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should NOT get ckey 3381968 in the results
    And I should get ckey 3148369 in the results
    And I should get the same number of results as a title search for "beyond race in a race NOT obsessed world"
    And I should get the same number of results as a title search for "beyond race in a race world NOT obsessed"
    And I should get fewer results than a title search for "beyond race in a race world"

  Scenario: HYPHEN space before but not after, TITLE search, in PHRASE, 3 add'l terms, 2 stopwords: ignore Hyphen 
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"beyond race in a race -obsessed world\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 3381968 in the results
    And I should get the same number of results as a title search for "\"beyond race in a race obsessed world\""

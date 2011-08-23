@searching @punctuation
Feature: Search Queries Containing AMPERSANDS (&)  (Stanford)
  In order to get correct search results for queries containing ampersands
  As an end user, when I enter a search query with ampersands
  I want to see comprehensible search results with awesome relevancy, recall, precision  
 
  Scenario: 2 term query with AMPERSAND, 0 Stopwords  (VUF-831)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Bandits & Bureaucrats"
    And I press "search"
    Then I should get at least 5 results
    And I should get ckey 2972993 in the first 1 results
    And I should get the same number of results as a search for "Bandits Bureaucrats"
    And I should get more results than a search for "\"Bandits Bureaucrats\""
    
  Scenario: 2 term PHRASE query with AMPERSAND, 0 Stopwords  (VUF-831)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Bandits & Bureaucrats\""
    And I press "search"
    Then I should get ckey 2972993 in the first 1 results
    And I should get the same number of results as a search for "\"Bandits Bureaucrats\""

  Scenario: 2 term TITLE query with AMPERSAND, 0 Stopwords  (VUF-831)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Bandits & Bureaucrats"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2972993 in the first 1 results
    And I should get the same number of results as a title search for "Bandits Bureaucrats"
    
  Scenario: 2 term TITLE PHRASE query with AMPERSAND, 0 Stopwords  (VUF-831)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Bandits & Bureaucrats\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2972993 in the first 1 results
    And I should get the same number of results as a title search for "\"Bandits Bureaucrats\""



  Scenario: 2 term query with AMPERSAND, 0 Stopwords
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "time & money"
    And I press "search"
    Then I should get ckey 3042571 in the first 2 results
    And I should get the same number of results as a search for "time money"
    And I should get more results than a search for "\"time money\""

  Scenario: 2 term TITLE query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "time & money"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 3042571 in the first 2 results
    And I should get the same number of results as a title search for "time money"
    And I should get more results than a title search for "\"time money\""



  Scenario: 2 term query with AMPERSAND, 1 Stopword 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "of time & place"
    And I press "search"
    Then I should get ckey 2186298 in the first 1 results  
    And I should get the same number of results as a search for "of time place"
    And I should get more results than a search for "\"of time place\""

  Scenario: 2 term PHRASE query with AMPERSAND, 1 Stopword  
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"of time & place\""
    And I press "search"
    Then I should get ckey 2186298 in the first 1 results  
    And I should get the same number of results as a search for "\"of time place\""

  Scenario: 2 term TITLE query with AMPERSAND, 1 Stopword 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "of time & place"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2186298 in the first 1 results  
    And I should get the same number of results as a title search for "of time place"
    And I should get more results than a title search for "\"of time place\""

  Scenario: 2 term TITLE PHRASE query with AMPERSAND, 1 Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"of time & place\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2186298 in the first 1 results  
    And I should get the same number of results as a title search for "\"of time place\""



  Scenario: 3 term query with AMPERSAND, 0 Stopwords  (SW-85)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "ESRI data & maps"
    And I press "search"
    Then I should get at least 10 of these ckeys in the first 15 results: "5468146, 4244185, 5412572, 5412597, 4798829, 4554456, 7652136, 5675395, 6738945, 5958512"
    And I should get the same number of results as a search for "ESRI data maps"
    And I should get more results than a search for "\"ESRI data maps\""

  Scenario: 3 term PHRASE query with AMPERSAND, 0 Stopwords  (SW-85)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"ESRI data & maps\""
    And I press "search"
    Then I should get at least 10 of these ckeys in the first 15 results: "5468146, 4244185, 5412572, 5412597, 4798829, 4554456, 7652136, 5675395, 6738945, 5958512"
    And I should get the same number of results as a search for "\"ESRI data maps\""

  Scenario: 3 term TITLE query with AMPERSAND, 0 Stopwords  (SW-85)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "ESRI data & maps"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 10 of these ckeys in the first 15 results: "5468146, 4244185, 5412572, 5412597, 4798829, 4554456, 7652136, 5675395, 6738945, 5958512"
    And I should get the same number of results as a title search for "ESRI data maps"
    And I should get more results than a title search for "\"ESRI data maps\""

  Scenario: 3 term TITLE PHRASE query with AMPERSAND, 0 Stopwords  (SW-85)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"ESRI data & maps\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 10 of these ckeys in the first 15 results: "5468146, 4244185, 5412572, 5412597, 4798829, 4554456, 7652136, 5675395, 6738945, 5958512"
    And I should get the same number of results as a title search for "\"ESRI data maps\""



  Scenario: 3 term query with AMPERSAND, 0 Stopwords   (VUF-1057)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Crystal growth & design"
    And I press "search"
    Then I should get ckey 4371266 in the first 1 results  
    And I should get the same number of results as a search for "Crystal growth design"
    And I should get more results than a search for "\"Crystal growth design\""

  Scenario: 3 term PHRASE query with AMPERSAND, 0 Stopwords   (VUF-1057)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Crystal growth & design\""
    And I press "search"
    Then I should get ckey 4371266 in the first 1 results  
    And I should get the same number of results as a search for "\"Crystal growth design\""

  Scenario: 3 term TITLE query with AMPERSAND, 0 Stopwords   (VUF-1057)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Crystal growth & design"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 4371266 in the first 1 results  
    And I should get the same number of results as a title search for "Crystal growth design"
    And I should get more results than a title search for "\"Crystal growth design\""

  Scenario: 3 term TITLE PHRASE query with AMPERSAND, 0 Stopwords  (VUF-1057)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Crystal growth & design\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 4371266 in the first 1 results  
    And I should get the same number of results as a title search for "\"Crystal growth design\""



  Scenario: 3 term query with AMPERSAND, 0 Stopwords   (VUF-1100)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Fish & Shellfish Immunology"
    And I press "search"
    Then I should get ckey 2405684 in the first 1 results  
    And I should get the same number of results as a search for "Fish Shellfish Immunology"
    And I should get more results than a search for "\"Fish Shellfish Immunology\""

  Scenario: 3 term PHRASE query with AMPERSAND, 0 Stopwords   (VUF-1100)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Fish & Shellfish Immunology\""
    And I press "search"
    Then I should get ckey 2405684 in the first 1 results  
    And I should get the same number of results as a search for "\"Fish Shellfish Immunology\""

  Scenario: 3 term TITLE query with AMPERSAND, 0 Stopwords   (VUF-1100)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Fish & Shellfish Immunology"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2405684 in the first 1 results  
    And I should get the same number of results as a title search for "\"Fish Shellfish Immunology\""

  Scenario: 3 term TITLE PHRASE query with AMPERSAND, 0 Stopwords  (VUF-1100)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Fish & Shellfish Immunology\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2405684 in the first 1 results  
    And I should get the same number of results as a title search for "\"Fish Shellfish Immunology\""



  Scenario: 3 term query with AMPERSAND, 0 Stopwords   (VUF-1150)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Environmental Science & Technology"
    And I press "search"
    Then I should get ckey 2956046 in the first 1 result
    And I should get the same number of results as a search for "Environmental Science Technology"
    And I should get more results than a search for "\"Environmental Science Technology\""

  Scenario: 3 term PHRASE query with AMPERSAND, 0 Stopwords   (VUF-1150)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Environmental Science & Technology\""
    And I press "search"
    Then I should get ckey 2956046 in the first 1 result
    And I should get the same number of results as a search for "\"Environmental Science Technology\""

  Scenario: 3 term TITLE query with AMPERSAND, 0 Stopwords   (VUF-1150)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Environmental Science & Technology"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2956046 in the first 1 result
    And I should get the same number of results as a title search for "Environmental Science Technology"
    And I should get more results than a title search for "\"Environmental Science Technology\""

  Scenario: 3 term TITLE PHRASE query with AMPERSAND, 0 Stopwords  (VUF-1150)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Environmental Science & Technology\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2956046 in the first 1 result
    And I should get the same number of results as a title search for "\"Environmental Science Technology\""



  Scenario: 3 term query with AMPERSAND, 2 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Zen & the Art of Motorcycle"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "7742806, 1464048"
    And I should get the same number of results as a search for "Zen the Art of Motorcycle"

  Scenario: 3 term PHRASE query with AMPERSAND, 2 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Zen & the Art of Motorcycle\""
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "7742806, 1464048"
    And I should get the same number of results as a search for "\"Zen the Art of Motorcycle\""

  Scenario: 3 term TITLE query with AMPERSAND, 2 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Zen & the Art of Motorcycle"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "7742806, 1464048"
    And I should get the same number of results as a title search for "Zen the Art of Motorcycle"

  Scenario: 3 term TITLE PHRASE query with AMPERSAND, 2 Stopwords
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Zen & the Art of Motorcycle\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "7742806, 1464048"
    And I should get the same number of results as a title search for "\"Zen the Art of Motorcycle\""



  Scenario: 3 term query with AMPERSAND, 2 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "anatomy of the dog & cat"
    And I press "search"
    Then I should get ckey 3324413 in the first 1 results  
    And I should get the same number of results as a search for "anatomy of the dog cat"
    And I should get more results than a search for "\"anatomy of the dog cat\""



  Scenario: 3 term TITLE query with AMPERSAND, 2 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "horn violin & piano"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 288389 in the first 11 results  
    And I should get the same number of results as a title search for "horn violin piano"
    And I should get more results than a title search for "\"horn violin piano\""



  Scenario: 4 term query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "crosby stills nash & young"
    And I press "search"
    Then I should get ckey 5627798 in the first 1 results
    And I should get the same number of results as a search for "crosby stills nash young"

  Scenario: 4 term PHRASE query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"crosby stills nash & young\""
    And I press "search"
    Then I should get ckey 5627798 in the first 1 results
    And I should get the same number of results as a search for "\"crosby stills nash young\""

  Scenario: 4 term TITLE query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "crosby stills nash & young"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 5627798 in the first 1 results
    And I should get the same number of results as a title search for "crosby stills nash young"

  Scenario: 4 term TITLE PHRASE query with AMPERSAND, 0 Stopwords
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"crosby stills nash & young\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 5627798 in the first 1 results
    And I should get the same number of results as a title search for "\"crosby stills nash young\""



  Scenario: 4 term query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "steam boat & canal routes"
    And I press "search"
    Then I should get ckey 5723944 in the first 1 results
    And I should get the same number of results as a search for "steam boat canal routes"
    And I should get more results than a search for "\"steam boat canal routes\""

  Scenario: 4 term TITLE query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "steam boat & canal routes"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 5723944 in the first 1 results
    And I should get the same number of results as a title search for "steam boat canal routes"
    And I should get more results than a title search for "\"steam boat canal routes\""



  Scenario: 4 term query with AMPERSAND, 2 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Zen & the Art of Motorcycle maintenance"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "7742806, 1464048"
    And I should get the same number of results as a search for "Zen the Art of Motorcycle maintenance"

  Scenario: 4 term PHRASE query with AMPERSAND, 2 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Zen & the Art of Motorcycle maintenance\""
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "7742806, 1464048"
    And I should get the same number of results as a search for "\"Zen the Art of Motorcycle maintenance\""

  Scenario: 4 term TITLE query with AMPERSAND, 2 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Zen & the Art of Motorcycle maintenance"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "7742806, 1464048"
    And I should get the same number of results as a title search for "Zen the Art of Motorcycle maintenance"

  Scenario: 4 term TITLE PHRASE query with AMPERSAND, 2 Stopwords
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Zen & the Art of Motorcycle maintenance\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 2 of these ckeys in the first 2 results: "7742806, 1464048"
    And I should get the same number of results as a title search for "\"Zen the Art of Motorcycle maintenance\""



  Scenario: 4 term query with AMPERSAND, 2 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "the truth about cats & dogs"
    And I press "search"
    Then I should get ckey 5646609 in the first 1 results  
    And I should get the same number of results as a search for "the truth about cats dogs"
    And I should get more results than a search for "\"the truth about cats dogs\""

  Scenario: 4 term TITLE query with AMPERSAND, 2 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "the truth about cats & dogs"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 5646609 in the first 1 results  
    And I should get the same number of results as a title search for "the truth about cats dogs"
    And I should get more results than a title search for "\"the truth about cats dogs\""



  Scenario: 5 term query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "horns, violins, viola, cello & organ"
    And I press "search"
    Then I should get ckey 6438612 in the first 1 results
    And I should get the same number of results as a search for "horns, violins, viola, cello organ"
    And I should get more results than a search for "\"horns, violins, viola, cello organ\""

  Scenario: 5 term PHRASE query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"horns, violins, viola, cello & organ\""
    And I press "search"
    Then I should get ckey 6438612 in the first 1 results
    And I should get the same number of results as a search for "\"horns, violins, viola, cello organ\""

  Scenario: 5 term TITLE query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "horns, violins, viola, cello & organ"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 6438612 in the first 1 results
    And I should get the same number of results as a title search for "horns, violins, viola, cello organ"
    And I should get more results than a title search for "\"horns, violins, viola, cello organ\""

  Scenario: 5 term TITLE PHRASE query with AMPERSAND, 0 Stopwords
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"horns, violins, viola, cello & organ\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 6438612 in the first 1 results
    And I should get the same number of results as a title search for "\"horns, violins, viola, cello organ\""



  Scenario: 5 term query with AMPERSAND, 1 Stopword 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Dr. Seuss & Mr. Geisel : a biography"
    And I press "search"
    Then I should get ckey 2997769 in the first 1 results
    And I should get the same number of results as a search for "Dr. Seuss Mr. Geisel : a biography"

  Scenario: 5 term PHRASE query with AMPERSAND, 1 Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Dr. Seuss & Mr. Geisel : a biography\""
    And I press "search"
    Then I should get ckey 2997769 in the first 1 results
    And I should get the same number of results as a search for "\"Dr. Seuss Mr. Geisel : a biography\""

  Scenario: 5 term TITLE query with AMPERSAND, 1 Stopword 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Dr. Seuss & Mr. Geisel : a biography"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2997769 in the first 1 results
    And I should get the same number of results as a title search for "Dr. Seuss Mr. Geisel : a biography"

  Scenario: 5 term TITLE PHRASE query with AMPERSAND, 1 Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Dr. Seuss & Mr. Geisel : a biography\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2997769 in the first 1 results
    And I should get the same number of results as a title search for "\"Dr. Seuss Mr. Geisel : a biography\""



  Scenario: 6 term query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "horns, violins, viola, cello & organ continuo"
    And I press "search"
    Then I should get ckey 6438612 in the first 1 results
    And I should get the same number of results as a search for "horns, violins, viola, cello organ continuo"
    And I should get more results than a search for "\"horns, violins, viola, cello organ continuo\""

  Scenario: 6 term PHRASE query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"horns, violins, viola, cello & organ continuo\""
    And I press "search"
    Then I should get ckey 6438612 in the first 1 results
    And I should get the same number of results as a search for "\"horns, violins, viola, cello organ continuo\""

  Scenario: 6 term TITLE query with AMPERSAND, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "horns, violins, viola, cello & organ continuo"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 6438612 in the first 1 results
    And I should get the same number of results as a title search for "horns, violins, viola, cello organ continuo"
    And I should get more results than a title search for "\"horns, violins, viola, cello organ continuo\""

  Scenario: 6 term TITLE PHRASE query with AMPERSAND, 0 Stopwords
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"horns, violins, viola, cello & organ continuo\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 6438612 in the first 1 results
    And I should get the same number of results as a title search for "\"horns, violins, viola, cello organ continuo\""



  Scenario: 6 term query with AMPERSAND, 1 Stopword 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Practical legal problems in music & recording industry"
    And I press "search"
    Then I should get ckey 1804064 in the first 1 results
    And I should get the same number of results as a search for "Practical legal problems in music recording industry"

  Scenario: 6 term PHRASE query with AMPERSAND, 1 Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Practical legal problems in music & recording industry\""
    And I press "search"
    Then I should get ckey 1804064 in the first 1 results
    And I should get the same number of results as a search for "\"Practical legal problems in music recording industry\""

  Scenario: 6 term TITLE query with AMPERSAND, 1 Stopword 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Practical legal problems in music & recording industry"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 1804064 in the first 1 results
    And I should get the same number of results as a title search for "Practical legal problems in music recording industry"

  Scenario: 6 term TITLE PHRASE query with AMPERSAND, 1 Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Practical legal problems in music recording industry\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 1804064 in the first 1 results
    And I should get the same number of results as a title search for "\"Practical legal problems in music recording industry\""



  Scenario: multiple AMPERSANDs, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Bob & Carol & Ted & Alice"
    And I press "search"
    Then I should get ckey 5742243 in the first 1 results
    And I should get the same number of results as a search for "Bob Carol & Ted & Alice"
    And I should get the same number of results as a search for "Bob & Carol Ted & Alice"
    And I should get the same number of results as a search for "Bob & Carol & Ted Alice"
    And I should get the same number of results as a search for "Bob Carol Ted & Alice"
    And I should get the same number of results as a search for "Bob Carol & Ted Alice"
    And I should get the same number of results as a search for "Bob & Carol Ted Alice"
    And I should get the same number of results as a search for "Bob Carol Ted Alice"

  Scenario: multiple AMPERSANDs, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Bob & Carol & Ted & Alice\""
    And I press "search"
    Then I should get ckey 5742243 in the first 1 results
    And I should get the same number of results as a search for "\"Bob Carol & Ted & Alice\""
    And I should get the same number of results as a search for "\"Bob & Carol Ted & Alice\""
    And I should get the same number of results as a search for "\"Bob & Carol & Ted Alice\""
    And I should get the same number of results as a search for "\"Bob Carol Ted & Alice\""
    And I should get the same number of results as a search for "\"Bob Carol & Ted Alice\""
    And I should get the same number of results as a search for "\"Bob & Carol Ted Alice\""
    And I should get the same number of results as a search for "\"Bob Carol Ted Alice\""

  Scenario: multiple AMPERSANDs, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Bob & Carol & Ted & Alice"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 5742243 in the first 1 results
    And I should get the same number of results as a title search for "Bob & Carol & Ted & Alice"
    And I should get the same number of results as a title search for "Bob Carol & Ted & Alice"
    And I should get the same number of results as a title search for "Bob & Carol Ted & Alice"
    And I should get the same number of results as a title search for "Bob & Carol & Ted Alice"
    And I should get the same number of results as a title search for "Bob Carol Ted & Alice"
    And I should get the same number of results as a title search for "Bob Carol & Ted Alice"
    And I should get the same number of results as a title search for "Bob & Carol Ted Alice"
    And I should get the same number of results as a title search for "Bob Carol Ted Alice"

  Scenario: multiple AMPERSANDs, 0 Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Bob & Carol & Ted & Alice\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 5742243 in the first 1 results
    And I should get the same number of results as a title search for "\"Bob Carol & Ted & Alice\""
    And I should get the same number of results as a title search for "\"Bob & Carol Ted & Alice\""
    And I should get the same number of results as a title search for "\"Bob & Carol & Ted Alice\""
    And I should get the same number of results as a title search for "\"Bob Carol Ted & Alice\""
    And I should get the same number of results as a title search for "\"Bob Carol & Ted Alice\""
    And I should get the same number of results as a title search for "\"Bob & Carol Ted Alice\""
    And I should get the same number of results as a title search for "\"Bob Carol Ted Alice\""

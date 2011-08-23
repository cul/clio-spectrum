@searching @punctuation
Feature: Search Queries Containing COLONS  (Stanford)
  In order to get correct search results for queries containing colons
  As an end user, when I enter a search query with colons
  I want to see comprehensible search results with awesome relevancy, recall, precision  
  #  note that a space before, but not after a colon is highly unlikely
 
  Scenario: Two term query with COLON, no Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Jazz : photographs"
    And I press "search"
    Then I should get ckey 2955977 in the results
    And I should get the same number of results as a search for "Jazz photographs"
    And I should get the same number of results as a search for "Jazz: photographs"

  Scenario: Two term PHRASE query with COLON, no Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Jazz : photographs\""
    And I press "search"
    Then I should get ckey 2955977 in the results
    And I should get the same number of results as a search for "\"Jazz photographs\"" 
    And I should get the same number of results as a search for "\"Jazz: photographs\""

  Scenario: Two term TITLE query with COLON, no Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Jazz : photographs"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2955977 in the results
    And I should get the same number of results as a title search for "Jazz photographs"
    And I should get the same number of results as a title search for "Jazz: photographs"

  Scenario: Two term TITLE PHRASE query with COLON, no Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Jazz : photographs\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 2955977 in the results
    And I should get the same number of results as a title search for "\"Jazz photographs\""
    And I should get the same number of results as a title search for "\"Jazz: photographs\""

  Scenario: Two term query with COLON, with Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Jazz : an introduction"
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "2130314, 3315875, 6794170"
    And I should get the same number of results as a search for "Jazz  an introduction"
    And I should get the same number of results as a search for "Jazz: an introduction"
    And I should get the same number of results as a search for "Jazz introduction"
    And I should get the same number of results as a search for "Jazz : introduction"
    And I should get the same number of results as a search for "Jazz: introduction"

  Scenario: Two term PHRASE query with COLON, with Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Jazz : an introduction\""
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "2130314, 3315875, 6794170"
    And I should get the same number of results as a search for "\"Jazz  an introduction\""
    And I should get the same number of results as a search for "\"Jazz: an introduction\""
# it gets fewer results without the stopword
#    And I should get the same number of results as a search for "\"Jazz introduction\""
#    And I should get the same number of results as a search for "\"Jazz : introduction\""
#    And I should get the same number of results as a search for "\"Jazz: introduction\""

  Scenario: Two term TITLE query with COLON, with Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Jazz : an introduction"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "2130314, 3315875, 6794170"
    And I should get the same number of results as a title search for "Jazz  an introduction"
    And I should get the same number of results as a title search for "Jazz: an introduction"
    And I should get the same number of results as a title search for "Jazz introduction"
    And I should get the same number of results as a title search for "Jazz : introduction"
    And I should get the same number of results as a title search for "Jazz: introduction"

  Scenario: Two term TITLE PHRASE query with COLON, with Stopword
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Jazz : an introduction\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 3 of these ckeys in the first 4 results: "2130314, 3315875, 6794170"
    And I should get the same number of results as a title search for "\"Jazz  an introduction\""
    And I should get the same number of results as a title search for "\"Jazz: an introduction\""
    And I should get the same number of results as a title search for "\"Jazz introduction\""
    And I should get the same number of results as a title search for "\"Jazz : introduction\""
    And I should get the same number of results as a title search for "\"Jazz: introduction\""

  Scenario: Three Terms with COLON, no Stopword 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Love : short stories"
    And I press "search"
    Then I should get ckey 4313015 in the results
    And I should get the same number of results as a search for "Love short stories"
    And I should get the same number of results as a search for "Love: short stories"

  Scenario: Three Term PHRASE with COLON, no Stopword 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Love : short stories\""
    And I press "search"
    Then I should get ckey 4313015 in the results
    And I should get the same number of results as a search for "\"Love short stories\""
    And I should get the same number of results as a search for "\"Love: short stories\""

  Scenario: Three Term TITLE query with COLON, no Stopword 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Love : short stories"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 4313015 in the results
    And I should get the same number of results as a title search for "Love short stories"
    And I should get the same number of results as a title search for "Love: short stories"

  Scenario: Three Term PHRASE TITLE  with COLON, no Stopword 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Love : short stories\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 4313015 in the results
    And I should get the same number of results as a title search for "\"Love short stories\""
    And I should get the same number of results as a title search for "\"Love: short stories\""

  Scenario: Three Terms with COLON and Stopword - (VUF 1104)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Tuna : a love story"
    And I press "search"
    Then I should get ckey 7698810 in the results
    And I should get the same number of results as a search for "Tuna  a love story"
    And I should get the same number of results as a search for "Tuna: a love story"
    And I should get the same number of results as a search for "Tuna love story"

  Scenario: Three Term PHRASE with COLON and Stopword - (VUF 1104)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Tuna : a love story\""
    And I press "search"
    Then I should get ckey 7698810 in the results
    And I should get the same number of results as a search for "\"Tuna a love story\""
    And I should get the same number of results as a search for "\"Tuna: a love story\""

  Scenario: Three Term TITLE query with COLON and Stopwords - (VUF 1058)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Fishes : an introduction to ichthyology"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 5 of these ckeys in the first 5 results: "5503532, 4150267, 3089293, 1307571, 1484390"
    And I should get the same number of results as a title search for "Fishes an introduction to ichthyology"
    And I should get the same number of results as a title search for "Fishes:  an introduction to ichthyology"
    And I should get the same number of results as a title search for "Fishes introduction ichthyology"

  Scenario: Three Term TITLE PHRASE query with COLON and Stopwords - (VUF 1058)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Fishes : an introduction to ichthyology\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get at least 5 of these ckeys in the first 5 results: "5503532, 4150267, 3089293, 1307571, 1484390"
    And I should get the same number of results as a title search for "\"Fishes an introduction to ichthyology\""
    And I should get the same number of results as a title search for "\"Fishes:  an introduction to ichthyology\""
    And I should get more results than a title search for "\"Fishes introduction ichthyology\""

  Scenario: Four Terms with COLON no Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Dance dance revolution : poems"
    And I press "search"
    Then I should get ckey 6860510 in the results
    And I should get the same number of results as a search for "Dance dance revolution poems"
    And I should get the same number of results as a search for "Dance dance revolution: poems"

  Scenario: Four Term PHRASE with COLON no Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When  I fill in the search box with "\"Dance dance revolution : poems\""
    And I press "search"
    Then I should get ckey 6860510 in the results
    And I should get the same number of results as a search for "\"Dance dance revolution poems\""
    And I should get the same number of results as a search for "\"Dance dance revolution: poems\""

  Scenario: Four Terms with COLON and Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Petroleum : the phenomenon of a modern panic"
    And I press "search"
    Then I should get ckey 3412285 in the results
    And I should get the same number of results as a search for "Petroleum the phenomenon of a modern panic"
    And I should get the same number of results as a search for "Petroleum: the phenomenon of a modern panic"
    And I should get the same number of results as a search for "Petroleum phenomenon modern panic"

  Scenario: Four Term PHRASE with COLON and Stopwords 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Petroleum : the phenomenon of a modern panic\""
    And I press "search"
    Then I should get ckey 3412285 in the results
    And I should get the same number of results as a search for "\"Petroleum the phenomenon of a modern panic\""
    And I should get the same number of results as a search for "\"Petroleum: the phenomenon of a modern panic\""
    And I should get more results than a search for "\"Petroleum phenomenon modern panic\""

  Scenario: Four Term TITLE query with COLON and 's, but no Stopwords, 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Jazz : America's classical music"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 3080095 in the results
    And I should get the same number of results as a title search for "Jazz America's classical music"
    And I should get the same number of results as a title search for "Jazz: America's classical music"
# is this desired behavior?    
    And I should get the same number of results as a title search for "Jazz America classical music"

  Scenario: Four Term TITLE PHRASE query with COLON and 's, but no Stopwords, 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Jazz : America's classical music\""
    And I select "Title" from "search_field"
    And I press "search"
    Then I should get ckey 3080095 in the results
    And I should get the same number of results as a title search for "\"Jazz America's classical music\""
    And I should get the same number of results as a title search for "\"Jazz: America's classical music\""
    And I should get the same number of results as a title search for "\"Jazz America classical music\""

  Scenario: Five terms with COLON with no Stopwords but with Braces
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Jazz. [videorecording] : anyone can improvise"
    And I press "search"
    Then I should get ckey 3995912 in the results
    And I should get the same number of results as a search for "Jazz. [videorecording] anyone can improvise"
    And I should get the same number of results as a search for "Jazz. [videorecording]: anyone can improvise"
    And I should get the same number of results as a search for "Jazz videorecording anyone can improvise"
      
  Scenario: Five term PHRASE with COLON with no Stopwords but with Braces
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Jazz. [videorecording] : anyone can improvise\""
    And I press "search"
    Then I should get ckey 3995912 in the results
    And I should get the same number of results as a search for "\"Jazz. [videorecording] anyone can improvise\""
    And I should get the same number of results as a search for "\"Jazz. [videorecording]: anyone can improvise\""
    And I should get the same number of results as a search for "\"Jazz videorecording anyone can improvise\""
  
  Scenario: Five terms with COLON and Stopwords  (VUF-522)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "The Beatles as musicians : Revolver through the Anthology"
    And I press "search"
    Then I should get ckey 4103922 in the results
    And I should get the same number of results as a search for "The Beatles as musicians Revolver through the Anthology"
    And I should get the same number of results as a search for "The Beatles as musicians: Revolver through the Anthology"
    And I should get the same number of results as a search for "Beatles musicians Revolver through Anthology"
  
  Scenario: Five term PHRASE with COLON and Stopwords  (VUF-522)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"The Beatles as musicians : Revolver through the Anthology\""
    And I press "search"
    Then I should get ckey 4103922 in the results
    And I should get the same number of results as a search for "\"The Beatles as musicians Revolver through the Anthology\""
    And I should get the same number of results as a search for "\"The Beatles as musicians: Revolver through the Anthology\""
    And I should get more results than a search for "\"Beatles musicians Revolver through Anthology\""

  Scenario: Six Terms with COLON and Stopwords - (SW-65)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "International encyclopedia of revolution and protest : 1500 to the present"
    And I press "search"
    Then I should get ckey 7930827 in the results
    And I should get the same number of results as a search for "International encyclopedia of revolution and protest 1500 to the present"
    And I should get the same number of results as a search for "International encyclopedia of revolution and protest: 1500 to the present"
    And I should get the same number of results as a search for "International encyclopedia revolution protest 1500 present"

  Scenario: Six Term PHRASE with COLON and Stopwords - (SW-65)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"International encyclopedia of revolution and protest : 1500 to the present\""
    And I press "search"
    Then I should get ckey 7930827 in the results
    And I should get the same number of results as a search for "\"International encyclopedia of revolution and protest 1500 to the present\""
    And I should get the same number of results as a search for "\"International encyclopedia of revolution and protest: 1500 to the present\""
    And I should get more results than a search for "\"International encyclopedia revolution protest 1500 present\""

  Scenario: Six Terms with COLON, Square Brackets, No Stopwords
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Qua-We-Na [microform]. : Native people"
    And I press "search"
    Then I should get ckey 485199 in the results
    And I should get the same number of results as a search for "Qua-We-Na [microform] Native people"
    And I should get the same number of results as a search for "Qua-We-Na [microform].: Native people"
    And I should get the same number of results as a search for "Qua-We-Na [microform]: Native people"
    And I should get the same number of results as a search for "Qua-We-Na microform : Native people"
    And I should get the same number of results as a search for "Qua-We-Na microform Native people"

  Scenario: Six Term PHRASE with COLON, Square Brackets, No Stopwords
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Qua-We-Na [microform]. : Native people\""
    And I press "search"
    Then I should get ckey 485199 in the results
    And I should get the same number of results as a search for "\"Qua-We-Na [microform] Native people\""
    And I should get the same number of results as a search for "\"Qua-We-Na [microform].: Native people\""
    And I should get the same number of results as a search for "\"Qua-We-Na [microform]: Native people\""
    And I should get the same number of results as a search for "\"Qua-We-Na microform : Native people\""
    And I should get the same number of results as a search for "\"Qua-We-Na microform Native people\""
      
  Scenario: Four Terms with COLON, Stopwords and Diacritics (VUF-1128)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "César Chávez : a voice for farmworkers"
    And I press "search"
    Then I should get ckey 6757167 in the results
    And I should get the same number of results as a search for "César Chávez  a voice for farmworkers"
    And I should get the same number of results as a search for "Cesar Chavez: a voice for farmworkers"
    And I should get the same number of results as a search for "Cesar Chavez voice farmworkers"

  Scenario: Four Term PHRASE with COLON, Stopwords and Diacritics (VUF-1128)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"César Chávez : a voice for farmworkers\""
    And I press "search"
    Then I should get ckey 6757167 in the results
    And I should get the same number of results as a search for "\"César Chávez  a voice for farmworkers\""
    And I should get the same number of results as a search for "\"Cesar Chavez: a voice for farmworkers\""
    And I should get more results than a search for "\"Cesar Chavez voice farmworkers\""

  Scenario: Query with Two COLONs
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Petroleum : exploration and exploitation in Norway : proceedings"
    And I press "search"
    Then I should get ckey 3114278 in the results
    And I should get the same number of results as a search for "Petroleum exploration and exploitation in Norway : proceedings"
    And I should get the same number of results as a search for "Petroleum: exploration and exploitation in Norway : proceedings"
    And I should get the same number of results as a search for "Petroleum : exploration and exploitation in Norway: proceedings"
    And I should get the same number of results as a search for "Petroleum : exploration and exploitation in Norway proceedings"
    And I should get the same number of results as a search for "Petroleum exploration and exploitation in Norway proceedings"
    And I should get the same number of results as a search for "Petroleum exploration exploitation Norway proceedings"

  Scenario: PHRASE Query with Two COLONs
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Petroleum : exploration and exploitation in Norway : proceedings\""
    And I press "search"
    Then I should get ckey 3114278 in the results
    And I should get the same number of results as a search for "\"Petroleum exploration and exploitation in Norway : proceedings\""
    And I should get the same number of results as a search for "\"Petroleum: exploration and exploitation in Norway : proceedings\""
    And I should get the same number of results as a search for "\"Petroleum : exploration and exploitation in Norway: proceedings\""
    And I should get the same number of results as a search for "\"Petroleum : exploration and exploitation in Norway proceedings\""
    And I should get the same number of results as a search for "\"Petroleum exploration and exploitation in Norway proceedings\""
    And I should get more results than a search for "\"Petroleum exploration exploitation Norway proceedings\""

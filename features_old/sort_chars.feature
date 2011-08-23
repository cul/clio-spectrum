# Should some of these be features, or just part of solrmarc functional tests?
Feature: Sorting Results
  In order to get perfect sort order
  As a user, when I sort my search results
  I want to see the search results in the proper order
     
  # particular characters result sorting
@fixme   
  Scenario: Spaces should be significant
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome

@fixme
  Scenario: Case / Capitalization should have no effect on sorting
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome

@fixme  
  Scenario: Letters with and without diacritics should be interfiled
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome
  
  Scenario: Æ and AE should be interfiled
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Æon"
    And I press "search"
    And I select "title" from "sort"
    And I press "sort_submit"
    Then I should get ckey 6628532 before ckey 4647437
    Then I should get ckey 6197318 before ckey 4647437
  
# TODO:  diacritics in first character;  subsequent characters  
@fixme
  Scenario: Non-filing indicators should be ignored for sorting.
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome

# TODO: maybe someday autodetect non-filing chars that aren't accommodated in the marc record

@fixme
  Scenario: Combination of non-filing characters and diacritics in first character should sort properly.
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
# Etude,   another example from vitus in email week of 4/27
    Then outcome

@fixme  
  Scenario: Punctuation should not affect sorting
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome

@fixme  
  Scenario: Hebrew alif and ayn should be ignored for sorting
# TODO:  as first character only, or as any character?
# TODO:  transliteration vs. hebrew script ... 
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome

@fixme
  Scenario: Znaks, hard and soft, should be ignored for sorting
# More information needed about znaks: is this a character?  a diacritic?  Should any occurrence be ignored?
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome

@fixme
  Scenario: Chinese - traditional and simplified characters should be sorted together
# More details needed about Chinese scripts
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome

@fixme
  Scenario: Japanese - old and new characters should sort together?
# More details needed about Japanese scripts
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome

@fixme
  Scenario: Korean - something about spaces vs. no space (?)
# Need more info about Korean spaces
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome

@fixme
  Scenario: Subscripts should be sorted properly
# super scripts;  what about $, %, etc.
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome

@fixme
  Scenario: Polish L should sort properly
# Need more information about Polish L
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When event
    Then outcome










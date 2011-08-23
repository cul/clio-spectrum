Feature: Application Header (Stanford)
  In order to see if the Header is being rendered correctly
  As a user
  I want to see the correct form elements

  Scenario: Look for text input on the home page
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    Then I should see a "input" element with "id" "q"
    
  Scenario: Look for search type drop down on the home page
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    Then I should see a "select" element with "id" "search_field"

  Scenario: Look for text input on the search results page
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    When I fill in "q" with "Buddhism"
    And I press "search"
    Then I should see a "input" element with "id" "q"
    
  Scenario: Look for search type drop down on the search results page
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    When I fill in "q" with "Buddhism"
    And I press "search"
    Then I should see a "select" element with "id" "search_field"
   
  Scenario: Look for text input on the record page
    Given a SOLR index with Stanford MARC data
    When I go to the show page for "6559055"
    Then I should see a "input" element with "id" "q"
    
  Scenario: Look for search type drop down on the record page
    Given a SOLR index with Stanford MARC data
    When I go to the show page for "6559055"
    Then I should see a "select" element with "id" "search_field"
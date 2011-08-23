Feature: Small result set
  In order to verify that the pagination renders when there is a small result set
  As a user
  I want to see the results numbers
  
  Scenario: one page result set
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Fishes an introduction to ichthyology"
    And I press "search"
    Then I should see "1 - 8 of 8 results"
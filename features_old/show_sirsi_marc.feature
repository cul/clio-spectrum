Feature: Show (Solr Document Detail Page) (Stanford Sirsi MARC)
  In order to have terrific utility of our Marc records 
  As a user
  I want to see appropriate data and interactions that work as expected
  
  Scenario: Author Link Should Give Appropriate Response
    Given a SOLR index with Stanford MARC data
    When I go to the show page for "832636"
    And I follow "Barna, Ion."
    Then I should get at least 2 results
  

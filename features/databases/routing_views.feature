@routing
Feature: Database routing
  In order to replace the RTI database app with a blacklight instance
  As an end user, I need to be able to select a datasource to limit searches to databases
  And as a programmer, I need to make sure that any links off the databases source
  link to database urls
 
  Scenario: performing a search
    When I search databases for "test"
    And I click on the "1st" result
    Then the path should include "/databases" 

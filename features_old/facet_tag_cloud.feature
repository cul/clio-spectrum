Feature: Home Page Tag Cloud (Stanford)
  In order to see if the Home page tag clouds exists
  As a user
  I want to see facet values represented as a tag cloud on the home page

  Scenario: Call Number
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    Then I should see "Archive of Recorded Sound"
    When I follow "Archive of Recorded Sound"
    Then I should see "[remove]"
    And I should get at least 10 results

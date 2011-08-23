Feature: Breadcrumb
  In order to see if the breadcrumb area is being rendered correclty
  As a user
  I want to see the correct html elements
  
  Scenario: Look for search constraints image on home page
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    When I fill in "q" with "Buddhism"
    And I press "search"
    Then I should see a "div" element with "id" "search-breadcrumb"
    And I should see a "div" element with "id" "startover"

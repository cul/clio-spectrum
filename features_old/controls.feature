Feature: Controls
  In order to verify that the controls bar is being rendered correctly
  As a user
  I want to see the correct html elements

  Scenario: pagination
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Keck"
    And I press "search"
    Then I should see "« Previous"
    And I should see "Next »"

  Scenario: search modifiers
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Keck"
		And I press "search"
		Then I should see a "div" element with "id" "sort_dropdown"
		And I should see a "div" element with "id" "per_page_dropdown"
		Then I should see a "select" element with "id" "sort"
		And I should see a "select" element with "id" "per_page"
  
  
    

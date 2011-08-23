Feature: Anchor Links
  As a user
  I want to see anchor links for screen readers
  
  Scenario: Home Page
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    Then I should see a "div" element with "id" "top_anchors"
    And I should see a "div" element with "id" "bottom_anchors"

  Scenario: Search Results
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "testing"
    And I press "search"
    Then I should see a "div" element with "id" "top_anchors"
    And I should see a "div" element with "id" "bottom_anchors"

  Scenario: Record Page
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "2757829"
    Then I should see a "div" element with "id" "top_anchors"
    And I should see a "div" element with "id" "bottom_anchors"
@searching
Feature: Sort and Per Page filters (Stanford)
  In order to see if the Sort and Per Page filters are being rendered correctly
  As a user
  I want to see the correct hidden elements passing the filter paramters

  Scenario: Look for appropriate filters when a facet is selected and and the results per page is changed
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    When I follow "Book"
    Then I should see a "span" element with "class" "selected"
    And I should see an "input" element with a "value" attribute of "Book"
    When I select "10" from "per_page"
    And I press "per_page_submit"
    Then I should see a "span" element with "class" "selected"
    
  Scenario: Look for appropriate filters when a facet is selected and and the sort is changed
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    When I follow "Book"
    Then I should see a "span" element with "class" "selected"
    And I should see an "input" element with a "value" attribute of "Book"
    When I select "author" from "sort"
    And I press "sort_submit"
    Then I should see a "span" element with "class" "selected"
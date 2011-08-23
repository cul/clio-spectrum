Feature: Pagination
  In order to verify that we the pagination is working correctly
  As a user
  I want to see awesome pagination

  Scenario: New search after paging
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "Happy"
    Then I press "search"
    Then I should get results
    When I follow "Next"
    Then I should get results
    When I fill in the search box with "Apple"
    And I press "search"
    And I should see a "span" element with "class" = "current" and with "1" inside
    And I should not see a "span" element with "class" = "current" and with "2" inside

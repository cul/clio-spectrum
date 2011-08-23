Feature: Item Information 
  As a user
  I want to see item details on response web pages
  
  Scenario: Show (record) View
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "1711966"
    And I press "search"
    And I follow "The horn"
    Then I should see "ML955 .J332 1988"
  
  Scenario: Search Results
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "1502056"
    And I press "search"
    Then I should see "At the Library"
    And I should see "ML955 .T898 1983"
  
  Scenario: Public Notes
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "6749799"
    Then I should see a "span" element with "class" = "public_note" and with "Original record sleeve lacking" inside
    When I am on the show page for "1711966"
    Then I should not see a "span" element with "class" "public_note"

  Scenario: Public Notes
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "7616046"
    Then I should see a "span" element with "class" "noncirc_page"
    And I should not see a "span" element with "class" "page"
    And I should not see a "span" element with "class" "noncirc"
    And I should not see a "span" element with "class" "unknown"
    And I should not see a "span" element with "class" "unavailable"

  Scenario: Jackson Records
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "8575777"
    Then I should see a link element with "L43324S" inside the href and "Check Jackson catalog for status" as the link text  

  Scenario: Lane Records
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "8381492"
    Then I should see a link element with "L289856" inside the href and "Check Lane catalog for status" as the link text


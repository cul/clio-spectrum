@searching
Feature: Call Numbers from index (Stanford)
  In order to see if the call numbers from the index are display correctly
  As a user
  I want to see the correct call numbers

  Scenario: The show view call numbers are being rendered when appropriate
    Given a SOLR index with Stanford MARC data
    When I go to the show page for "6559055"
    Then I should see a "ul" element with "class" "show_availability"
    
  Scenario: The At the Library section is not rendered on a record that doesn't have a valid callnumbers
    Given a SOLR index with Stanford MARC data
    When I go to the show page for "8105449"
    Then I should not see a "ul" element with "class" "show_availability"

  Scenario: The show view call numbers should be in volume reverse sort order for serials
    Given a SOLR index with Stanford MARC data
    When I go to the show page for "370790"
    Then I should get callnumber "570.5 .N287 V.25-26 1935" before callnumber "570.5 .N287 V.23-24 1934"
    Then I should get callnumber "570.5 .N287 V.21-22 1933" before callnumber "570.5 .N287 V.19-20 1932"
    Then I should get callnumber "570.5 .N287 V.17-18 1931" before callnumber "570.5 .N287 V.15-16 1930"
    
  Scenario: The show view call numbers should be in normal volume sort order for non-serials
    Given a SOLR index with Stanford MARC data
    When I go to the show page for "376901"
    Then I should get callnumber "505 .S343 V.20 1972" before callnumber "505 .S343 V.21:1 1973"
    Then I should get callnumber "505 .S343 V.5 1949-1951" before callnumber "505 .S343 V.6 1954-1955"
    Then I should get callnumber "505 .S343 V.8 1957-1958" before callnumber "505 .S343 V.9 1959-1960"
    
  Scenario: The search results call numbers are being rendered when appropriate
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "7899103"
    And I press "search"
    Then I should see a "dd" element with "class" "availability_lookup"

  Scenario: The search results call numbers are not being rendered for records without call numbers
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "8212302"
    And I press "search"
    Then I should not see a "dd" element with "class" "availability_lookup"
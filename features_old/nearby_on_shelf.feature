Feature: Nearby on Shelf
  As a user
  I want to see the items that would be nearby this item on a virtual shelf
  
  Scenario: Simple Case
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "3329985"
    Then I should see a "div" element with "class" = "nearby_item" exactly 5 times

  Scenario: Item with no call number
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "7807395"
    Then I should not see a "div" element with "id" "nearby_items_div"

  Scenario: Item with no preferred barcode
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "51388"
    Then I should not see a "div" element with "id" "nearby_item_div"

  Scenario: Item with no shelfkey
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "7864015" 
    Then I should not see a "form" element with "id" "nearby_form"
    And I should see a "div" element with "id" "current_callnumber"

  Scenario: Item with multiple identical shelfkeys
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "404447"
    Then I should not see a "form" element with "id" "nearby_form"
    And I should see a "div" element with "id" "current_callnumber"

  Scenario: Item with multiple and different call numbers
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "8479138"
    Then I should see a "form" element with "id" "nearby_form"
    And I should see a "div" element with "id" "current_callnumber"


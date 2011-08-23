Feature: Request Info response
  As a service for the request forms application
  I want to see the request info and appropriate links

  Scenario: Standard record
    Given a SOLR index with Stanford MARC data
    When I am on the request info page for "713891" at "SAL3" library
    Then I should see a "record" xml element
    And I should see a "title" xml element
    And I should see a "pub_info" xml element
    And I should see a "physical_description" xml element
    And I should see a "item_details" xml element
    And I should see a "item" xml element
    And I should see a "id" xml element
    And I should see a "shelfkey" xml element
    And I should see a "copy_number" xml element
    And I should see a "item_number" xml element
    And I should see a "home_location" xml element
    And I should see a "current_location" xml element
    
    
  Scenario: SAL request links
    Given a SOLR index with Stanford MARC data
    # SAL1/2
    When I am on the show page for "8506357"
    Then I should see "Page for delivery from SAL"
    # SAL3
    When I am on the show page for "8533715"
    Then I should see "Page for delivery from SAL3"
    # SAL-Newark
    When I am on the show page for "4472091"
    Then I should see "Page for delivery from SAL Newark"
  
  
  Scenario: Hopkins Links
    Given a SOLR index with Stanford MARC data
    # Normal Hopkins record
    When I am on the show page for "8447045"
    Then I should see "Page for delivery from Hopkins"
    # Hopkins record that has another copy elsewhere
    When I am on the show page for "8494199"
    Then I should not see "Page for delivery from Hopkins"
    # Hopkins record that has an online copy
    When I am on the show page for "7807033"
    Then I should not see "Page for delivery from Hopkins"
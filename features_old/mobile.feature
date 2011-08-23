Feature: Mobile XML response
  As a mobile user
  I want to see XML elements representing the mobile response for the iStanford application

  Scenario: Standard record
    Given a SOLR index with Stanford MARC data
    When I am on the mobile show page for "2757829"
    Then I should see a "response" xml element
    And I should see a "title" xml element
    And I should see a "image_url" xml element
    And I should see a "image_url_lg" xml element
    And I should see a "formats" xml element
    And I should see a "format" xml element
    And I should see a "isbns" xml element
    And I should see a "isbn" xml element
    And I should see a "imprint" xml element
    And I should see a "item_id" xml element
    And I should see a "holdings" xml element
    And I should see a "library" xml element
    And I should see a "location" xml element
    And I should see a "callnumber" xml element
    And I should see a "availability" xml element

  Scenario: Mobile search result
    Given a SOLR index with Stanford MARC data
    When I am on the mobile search page for "harry"
    Then I should see a "response" xml element
    And I should see a "lbitem" xml element
    And I should see a "title" xml element
    And I should see a "mobile_record" xml element
    And I should see a "image_url" xml element
    And I should see a "image_url_lg" xml element
    And I should see a "formats" xml element
    And I should see a "format" xml element
    And I should see a "availability" xml element
    
  Scenario: Contact info
    Given I am on the contact info page
    Then I should see a "library" xml element
    And I should see a "contact" xml element
    And I should see a "email" xml element
    And I should see a "urls" xml element
    And I should see a "url" xml element  
    And I should see a "phone" xml element
    And I should see a "name" xml element
    
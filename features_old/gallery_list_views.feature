Feature: Gallery and List Views
  In order to verify that the gallery and list views are working 
  As a user
  I want to see gallery and list documents
  
  Scenario: Gallery View for Search Results
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Search"
    And I press "search"
    When I follow "Gallery view"
    Then I should get results
    And I should see a "div" element with "class" "ajax_hover"
  
  Scenario: List View for Search Results
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Search"
    And I press "search"
    When I follow "List view"
    Then I should get results
    And I should see a "div" element with "class" "ajax_hover"
  

  Scenario: Gallery View for Browse
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "1297245"
    When I follow "Show full page"
    Then I should get results
    And I should see a "div" element with "class" "ajax_hover"

  Scenario: List View for Browse
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "1297245"
    When I follow "Show full page"
    Then I should get results
    When I follow "List view"
    Then I should get results
    And I should see a "div" element with "class" "ajax_hover"
    
  Scenario: 0 items search
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "asdfadsfadsfads"
    Then I should not see a "div" element with "id" "search_modifiers"
  
  
  
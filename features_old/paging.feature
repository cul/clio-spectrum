Feature: Paging
  In order to verify paging is working properly
  As a user
  I want awesome pagination

  Scenario: Adding facets
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in the search box with "\"Child psychotherapy.\""
    And I select "Subject terms" from "search_field"
    And I press "search"
    # Have to do this 5 times to get to the 6th page.  When I follow "6" does not work
    When I follow "Next »"
		When I follow "Next »"
		When I follow "Next »"
		When I follow "Next »"
    When I follow "Next »"
    And I follow "Green (Humanities & Social Sciences)"
		Then I should get results
  
  
  

  

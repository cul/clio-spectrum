Feature: List view
  In order to verify that I am looking at the list view
  As a user
  I want to see an awesome list

  Scenario: Normal List
    Given a SOLR index with Stanford MARC data
    When I am on the home page
		And I fill in "q" with "Geek"
		And I press "search"
		When I follow "list"
		Then I should get results
		And I should see a "div" element with "id" "list_list"
		And I should see a "div" element with "class" "ajax_hover"
  
  Scenario: Ajax Hover URL
    Given a SOLR index with Stanford MARC data
    When I am on the home page
		And I fill in "q" with "Geek"
		And I press "search"
		When I follow "list"
		Then I should get results
		And I should see a "div" element with "id" "list_list"
		And I should see a "div" element with "class" "ajax_hover"
		And I should see a "a" element with "class" "ajax_hover_url"
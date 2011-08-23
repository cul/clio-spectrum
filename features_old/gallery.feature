Feature: Gallery view
  In order to verify that I am looking at the gallery view
  As a user
  I want to see an awesome gallery

  Scenario: Normal Gallery
    Given a SOLR index with Stanford MARC data
    When I am on the home page
		And I fill in "q" with "Geek"
		And I press "search"
		When I follow "gallery"
		Then I should get results
		And I should see a "div" element with "id" "document_gallery"
		And I should see a "div" element with "class" "ajax_hover"
  
  Scenario: Ajax Hover URL
    Given a SOLR index with Stanford MARC data
    When I am on the home page
		And I fill in "q" with "Geek"
		And I press "search"
		When I follow "gallery"
		Then I should get results
		And I should see a "div" element with "id" "document_gallery"
		And I should see a "div" element with "class" "ajax_hover"
		And I should see a "a" element with "class" "ajax_hover_url"
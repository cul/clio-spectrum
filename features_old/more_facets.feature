Feature: More facets
  In order to verify that the more facets functionality is working
  As a user
  I want to get to the facet pagination page

  Scenario: Normal Search
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "searching"
    And I press "search"
    When I follow "more authors"
    Then I should see "Kumar"
    
    
  Scenario: Advanced Search
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I fill in "title" with "searching"
    And I check "fq_access_facet_At_the_Library"
    And I press "advanced_search_button"
    When I follow "more authors"
    Then I should see "Kumar"
  
  
  
  
  
  

  

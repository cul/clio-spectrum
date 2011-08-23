@searching
Feature: Advanced Search (Stanford)
  In order to get spectacular Advanced Search results
  As an end user, when I do Advanced Searches
  I want to see search results with awesome relevancy, recall, precision

  Scenario: Language facet ordering in advanced search form
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    # We have more Czech content, therefore if sorted by content, it would go highest
    Then I should get facet "Croatian" before facet "Czech"
    
  Scenario: Other facet ordering in advanced search form
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    Then I should get facet "Newspaper" before facet "Other"
    
  Scenario: An alphabetically high facet with low count should not display
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    Then the facet "Choctaw" should not display
    
  Scenario: An alphabetically low facet with high count should display
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    Then the facet "Russian" should display

  Scenario: Single Author Title search matches Socrates results
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I fill in "author" with "McRae"
    And I fill in "title" with "Jazz"
    And I press "advanced_search_button"
    Then I should get at least 4 of these ckeys in the first 4 results: "7637875, 336046, 6634054, 2130330"

  Scenario: Only facet searching
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I check "fq_access_facet_At_the_Library"
    And I check "fq_format_facet_Book"
    And I press "advanced_search_button"
    Then I should get results
    
  Scenario: No facet searching
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I fill in "title" with "something"
    And I press "advanced_search_button"
    Then I should get results
    
  Scenario: All fields ANDed filled in plus facets should return a result
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I fill in "author" with "Rowling"
    And I fill in "title" with "Potter"
    And I fill in "subject" with "Wizards"
    And I fill in "description" with "Hogwarts"
    And I fill in "pub_info" with "London"
    And I fill in "number" with "0747591059"
    And I check "fq_format_facet_Book"
    And I press "advanced_search_button"
    Then I should get results
    
  Scenario: All fields ORed filled in plus facets should return a result
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I select "any" from "op"
    And I fill in "author" with "Rowling"
    And I fill in "title" with "Potter"
    And I fill in "subject" with "Wizards"
    And I fill in "description" with "Hogwarts"
    And I fill in "pub_info" with "London"
    And I fill in "number" with "0747591059"
    And I check "fq_format_facet_Book"
    And I press "advanced_search_button"
    Then I should get results
    
  Scenario: Form field modifying checkbox
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I fill in "description" with "Hogwarts"
    And I press "advanced_search_button"
    Then I should get at least 25 total results
    And I should not see "TOC/Summary"
    When I go to the advanced search page
    And I fill in "description" with "Hogwarts"
    And I check "description_check"
    And I press "advanced_search_button"
    Then I should get at most 20 total results
    And I should see "TOC/Summary"
    
  Scenario: Advances search sorting
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I fill in "author" with "Rowling"
    And I fill in "title" with "Potter"
    And I select "year (old to new)" from "sort"
    And I press "advanced_search_button"
    Then I should get at least 1 of these ckeys in the first 2 results: "4819125"
    And I select "title" from "sort"
    And I press "sort_submit"
    Then I should get at least 1 of these ckeys in the first 4 results: "5453649"
    And I select "year (old to new)" from "sort"
    And I press "sort_submit"
    Then I should get at least 1 of these ckeys in the first 2 results: "4819125"
    
  Scenario: NOT queries
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I fill in "author" with "Rowling"
    And I fill in "title" with "NOT potter"
    And I press "advanced_search_button"
    Then I should not see "Harry Potter"
    When I go to the advanced search page

  Scenario: AND and ORs
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page 
    And I fill in "author" with "John Steinbeck"
    And I fill in "title" with "Pearl OR Grapes"
    And I press "advanced_search_button"
    Then I should get at least 2 of these ckeys in the first 20 results: "6746743, 6747313"

  Scenario: China History Women
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I fill in "subject" with "china women history"
    And I check "fq_language_English"
    And I press "advanced_search_button"
    Then I should get at least 100 total results
    
  Scenario: Single facet Query
	Given a SOLR index with Stanford MARC data
	When I go to the advanced search page
	And I fill in "description" with "Sally Ride"
	And I check "fq_building_facet_Physics"
	And I press "advanced_search_button"
	Then I should get at most 1 result

  Scenario: Multi-Facet Query
    Given a SOLR index with Stanford MARC data
    When I go to the advanced search page
    And I fill in "description" with "African Maps"
    And I check "fq_format_facet_Map_Globe"
    And I check "fq_building_facet_Music"
    And I press "advanced_search_button"
    Then I should not get results
    
  Scenario: Checking specific CKeys from Advanced Search facet results
	Given a SOLR index with Stanford MARC data
	When I go to the advanced search page
	And I fill in "author" with "Rowling"
	And I fill in "title" with "Potter"
	And I check "fq_format_facet_Book"
	And I press "advanced_search_button"
	Then I should get ckey 5680298 in the results
	Then I should not get ckey 8303176 in the results
	
  Scenario: Checking more specific CKeys from Advanced Search facet results
	Given a SOLR index with Stanford MARC data
	When I go to the advanced search page
	And I fill in "author" with "Rowling"
	And I fill in "title" with "Potter"
	And I check "fq_format_facet_Video"
	And I press "advanced_search_button"
	Then I should get ckey 8303176 in the results
	Then I should not get ckey 5680298 in the results
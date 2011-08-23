@searching
Feature: Author Search Result Relevancy (Stanford)
  In order to get fantastic author search results
  As an end user, when I do author searches
  I want to see search results with awesome relevancy, recall, precision

  Scenario: Author matches should appear before editor matches
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "jill k. conway"
    And I select "Author" from "search_field"
    And I press "search"
    Then I should get ckey 4735430 in the results
    And I should get the same number of results as an author search for "jill k conway"
    # author before editor
    And I should get ckey 1490381 before ckey 4343662
    And I should get ckey 1302403 before ckey 4343662
    And I should get ckey 861080 before ckey 4343662
    And I should get ckey 1714776 before ckey 4343662
    And I should get ckey 2911421 before ckey 4343662
    And I should get ckey 2937495 before ckey 4343662
    And I should get ckey 3063723 before ckey 4343662
    And I should get ckey 3832670 before ckey 4343662
    And I should get ckey 4735430 before ckey 4343662
    # editor
    And I should get ckey 4343662 in the results
    And I should get ckey 1714390 in the results
    And I should get ckey 2781921 in the results
    #  in metadata, but not as author
    # book about her, with name in title spelled Ker
    And I should not get ckey 5826712 in the results
    # the next two are in spanish and have the name in the 505a
    And I should not get ckey 3159425 in the results
    And I should not get ckey 4529441 in the results

# TODO: move to sorting feature?  to author_sorting feature?
  Scenario: Results sorted by author should be by author, then by title
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "jill k. conway"
    And I select "Author" from "search_field"
    And I press "search"
    And I select "author" from "sort"
    And I press "sort_submit"
    Then I should get ckey 1490381 before ckey 861080
    # next two have same title 
    And I should get ckey 1302403 before ckey 1714776
    And I should get ckey 861080 before ckey 1714776
    # next two have same title 
    And I should get ckey 1714776 before ckey 2937495
    And I should get ckey 2911421 before ckey 2937495
    And I should get ckey 2937495 before ckey 3063723
    And I should get ckey 3063723 before ckey 3832670
    And I should get ckey 3832670 before ckey 4735430
    And I should get ckey 4735430 before ckey 4343662
    # the following books are edited by her, rather than written by her
    And I should get ckey 4343662 before ckey 1714390
    And I should get ckey 1714390 before ckey 2781921
    And I should get ckey 2781921 before ckey 2461493

  Scenario: Search for non-existent author should yield zero results
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "jill kerr conway"
    And I select "Author" from "search_field"
    And I press "search"
    Then I should get at most 0 results

  Scenario: Jane Austen author search results should have videos (from 700 fields)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "jane austen"
    And I select "Author" from "search_field"
    And I press "search"
    Then I should see "Video"

  Scenario: 700 added authors should be included in author search
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "jane hannaway"
    And I select "Author" from "search_field"
    And I press "search"
    Then I should get ckey 2503795 in the results

  Scenario: Thesis advisors (720 fields) should be included in author search
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Zare"
    And I select "Author" from "search_field"
    And I press "search"
    Then I should get at least 10 results
    And I should see "Thesis"
  
  Scenario: corporate author should be included in author search
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    # other examples:  "Plateau State", tanganyika, gold coast
    When I fill in "q" with "Anambra State"
    And I select "Author" from "search_field"
    And I press "search"
    Then I should get at least 80 total results
    
  Scenario: Unstemmed Author Names Should Precede Stemmed Variants
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "Zare"
    And I select "Author" from "search_field"
    And I press "search"
    Then I should not get result author "Zaring, Wilson M." in the first 20 results
    And I should not get result author "Stone, Grace Zaring, 1891-" in the first 20 results
    
  Scenario: "john steinbeck author search should have english titles first"
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "john steinbeck"
    And I select "Author" from "search_field"
    And I press "search"
    Then I should not get ckey 6284117 in the first 5 results
    And I should not get ckey 6747470 in the first 5 results  
    And I should get ckey 4814638 in the first 6 results
    And I should get ckey 2978767 in the first 6 results
    And I should get ckey 2246445 in the first 6 results
    And I should get ckey 2978768 in the first 6 results
  
  
  


Feature: Sorting Results
  In order to get perfect sort order
  As a user, when I sort my search results
  I want to see the search results in the proper order
  
  Scenario: empty query sort:  not in ckey order
    Given a SOLR index with Stanford MARC data
    When I go to the catalog page
    Then I should not get ckey 1 in the first 1 results
  
  Scenario: empty query sort:  pub date desc, then title asc
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "Book"
    And I select "100" from "per_page"
    And I press "per_page_submit"
    And I follow "This year"
    Then I should get ckey 8550544 before ckey 8519432

  Scenario: default sort: score, then pub date desc, then title asc
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I follow "Online"
    Then I should not get ckey 7342 in the first 1 results
  
  Scenario: relevance sort explicitly selected: score, then pub date desc, then title asc
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I follow "Newspaper"
    And I select "author" from "sort"
    And I press "sort_submit"
    And I select "relevance" from "sort"
    And I press "sort_submit"
    # alpha for 2007
    Then I should get ckey 7141368 before ckey 7097229
    # newer year (2007) before older year (2005)
    And I should get ckey 8214257 before ckey 5985299
  
  Scenario: author sort: author asc, then title asc
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "jill k. conway"
    And I select "Author" from "search_field"
    And I press "search"
    And I select "author" from "sort"
    And I press "sort_submit"
    Then I should get ckey 2911421 before ckey 2937495
  
  Scenario: title sort: title asc, then pub date desc
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "jill k. conway"
    And I select "Author" from "search_field"
    And I press "search"
    And I select "title" from "sort"
    And I press "sort_submit"
    # same title, pub date 1990 before pub date 1989 
    Then I should get ckey 2911421 before ckey 1714776
  
  Scenario: pub date sort: pub date desc, then title asc
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "jill k. conway"
    And I select "Author" from "search_field"
    And I press "search"
    And I select "year (new to old)" from "sort"
    And I press "sort_submit"
    # 2001 then 1999 
    Then I should get ckey 4735430 before ckey 4343662
    # True north before True North : a memoir
    And I should get ckey 2937495 before ckey 3063723

  Scenario:pub date sort: 9999 should not be the first pub date 
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I follow "Book"
    And I select "year (new to old)" from "sort"
    And I press "sort_submit"
    Then I should not see "9999"
  
  Scenario:pub date sort (old to new): 0000 should not be the first pub date 
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I follow "Book"
    And I select "year (old to new)" from "sort"
    And I press "sort_submit"
    Then I should not see "0000"

@searching
Feature: Number Searches (Stanford)
  In order to get correct number search results (ISBN, ISSN, OCLC, LCCN, ckey, barcode ...)
  As an end user, when I search for numbers
  I want to see search results with awesome relevancy, recall, precision
  
  Scenario: ISSN search should work with or without the hyphen
    Given  a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "1003-4730"
    And I press "search"
    Then I should get ckey 6210309 in the results
    And I should get the same number of results as a search for "10034730"

  Scenario: ISSN for "The Nation" should get perfect results, with and without a hyphen (linking/series after others)
    Given  a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "0027-8378"
    And I press "search"
    Then I should get at least 4 of these ckeys in the first 4 results: "464445, 497417, 3448713, 7557007"
    #  additional ckeys:   1771808 (in 500a),  5724779  (in 776x)
    And I should get at least 2 of these ckeys in the first 6 results: "1771808, 5724779"
    And I should get the same number of results as a number search for "00278378"  

  Scenario: ISSN ending in X should not be case sensitive
    Given  a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "0046-225X"
    And I press "search"
    Then I should get ckey 359795 in the results
    And I should get the same number of results as a number search for "0046-225x"  

  Scenario: 10 and 13 digit ISBNs should both work
    Given  a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "0704322536"
    And I press "search"
    Then I should get ckey 1455294 in the results
    And I should get the same number of results as a number search for "9780704322530"  
  
  Scenario: ISBN ending in X should not be case sensitive
    Given  a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "287009776X"
    And I press "search"
    Then I should get ckey 4705736 in the results
    And I should get the same number of results as a number search for "287009776x"  
    
  Scenario:  Searching for ckey should result in ... that record!
    Given  a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "359795"
    And I press "search"
    Then I should get at most 1 result
    Then I should get ckey 359795 in the results

  Scenario:  Searching for barcode should work
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "36105018139407"
    And I press "search"
    Then I should get at most 1 result
    Then I should get ckey 6284429 in the results

  Scenario:  Searching for oclc number should work
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "61746916"
    And I press "search"
    Then I should get at most 1 result
    Then I should get ckey 6283711 in the results

# Next scenario is a FIXME because the leading 0 is no longer returning items.  If this is a critical feature we need to fix this.  If it is not, we can remove this scenario.
@fixme
  Scenario:  Searching for oclc number with leading zero should work
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    And I fill in "q" with "08313857"
    And I press "search"
    Then I should get at most 1 result
    Then I should get ckey 7138571 in the results

# LCCN no longer indexed
#  Scenario:  Searching for 10 digit lccn should work
#    Given a SOLR index with Stanford MARC data
#    When I go to the home page
#    And I fill in "q" with "2004005074"
#    And I press "search"
#    Then I should get at most 1 result
#    Then I should get ckey 5666733 in the results

#  Scenario:  Searching for 8 digit lccn should work
#    Given a SOLR index with Stanford MARC data
#    When I go to the home page
#    And I fill in "q" with "87017033"
#    And I press "search"
#    Then I should get at most 1 result
#    Then I should get ckey 1726910 in the results


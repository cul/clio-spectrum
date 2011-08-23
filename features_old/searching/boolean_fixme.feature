@searching, @fixme
Feature: NEEDS IMPROVEMENT: Boolean Operators (Stanford)
  In order to get fantastic search results
  As an end user, when I do searching with boolean terms or corresponding symbols
  I want to see search results that reflect the boolean query appropriately

# TODO:  can't search a query with a partial phrase - need step definition
#Scenario: hyphen for a "prohibited" phrase
#  Given a SOLR index with Stanford MARC data
#  And I go to the home page
#  When I fill in the search box with "mark twain -"tom sawyer""
#  And I press "search"
#  Then I should get at least 2 results
#  And I should get more results than a search for "mark twain "tom sawyer""
#  And I should get more results than a search for "mark twain tom sawyer"

  # see also dismax mm setting features for long multi-word queries
  
  Scenario: FIXME:  upper case AND  (not currently working same as lower case and ...)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "Catholic thought AND papal jury policy"
    And I press "search"
    Then I should get ckey 1711043 in the results
    And I should get the same number of results as a search for "Catholic thought and papal jury policy"

  # no such resource.  VUF-626.  Not even in socrates
  Scenario: FIXME:  upper case AND   and hyphen  (hyphen causes phrase search ...)
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I fill in "q" with "South Africa, Shakespeare AND post-colonial culture"
    And I press "search"
    Then I should get results
    And I should get the same number of results as a search for "South Africa, Shakespeare and post-colonial culture"
  




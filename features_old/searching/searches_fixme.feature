@searching, @fixme
Feature: NEEDS IMPROVEMENT: Search Result Relevancy (Stanford)
  In order to get improved search results
  As an end user, when I enter search terms
  I want to see search results with improved relevancy, recall, precision

# PUNCTUATION  
Scenario: FIXME:  Brackets not serving as range query should be ignored 
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in the search box with "Alice Wonderland serie[s]"
  And I press "search"
  Then I should get at least 2 results
  And I should get the same number of results as a search for "Alice Wonderland series"

# TODO:  can't search a query with a partial phrase - need step definition
Scenario: hyphen for prohibited phrase should be more forgiving of 
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in the search box with "mark twain -"tom sawyer""
  And I press "search"
  Then I should get at least 2 results
  And I should get the same number of results as a search for "Alice Wonderland series"

# TODO:  can't search a query with a partial phrase - need step definition
Scenario: "hyphen for prohibited phrase should work with parens as well as with quotes" 
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in the search box with "mark twain -"tom sawyer""
  And I press "search"
  And I should get the same number of results as a search for "mark twain -(tom sawyer)"
  And I should get the same number of results as a search for "mark twain -("tom sawyer")"

# TODO:  can't search a query with a partial phrase - need step definition
Scenario: "hyphen for prohibited phrase should be more forgiving of open quotes or parens" 
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in the search box with "mark twain -(tom sawyer)"
  And I press "search"
  And I should get the same number of results as a search for "mark twain -"tom sawyer""
  And I should get the same number of results as a search for "mark twain -(tom sawyer"
  And I should get the same number of results as a search for "mark twain -"tom sawyer"
  And I should get the same number of results as a search for "mark twain -("tom sawyer""
  And I should get the same number of results as a search for "mark twain -("tom sawyer)"

Scenario: FIXME:   Dismax special lone characters should politely return 0 results
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "+"
  And I press "search"
  Then I should get at most 0 results
  And I should get the same number of results as a search for "-"
# TODO:  need a way to search for double quote
#  And I should get the same number of results as a search for "\""

Scenario: FIXME:  Non-dismax special lone characters should politely return 0 results
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "."
  And I press "search"
  Then I should get at most 0 results
  And I should get the same number of results as a search for "'"
  And I should get the same number of results as a search for "&&"
  And I should get the same number of results as a search for "||"

#  This works for a title search, but not for an everything search ...
# TODO:  this should NOT be passing; it doesn't work in the actual UI
#   HOWEVER:  it is the same as the others in VuFind
Scenario: FIXME: Trailing ellipsis preceded by a space should be ignored - Title search
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "I want ..."
  And I press "search"
  And I should get ckey 7490934 in the results
  And I should get the same number of results as a search for "I want"

# this hyphen behaves like "NOT", which is not what we want.
Scenario: Hyphen with no space before or after should be ignored
  Given a SOLR index with Stanford MARC data
  When I am on the home page
  And I fill in "q" with "customer - driven academic library"
  And I press "search"
  Then I should get results
  And I should get the same number of results as a search for "customer driven academic library"


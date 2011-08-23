@searching, @fixme
Feature: Searching non-alphabetic characters  (Stanford)
  In order to get correct search results for words with non-alphabetic characters
  As an end user, when I enter search terms with or without non-alphabetic characters
  I want to see comprehensible search results with awesome relevancy, recall, precision  

Scenario: FIXME: colon as part of search should be ignored
  Given I am on the home page
  When I fill in "q" with "Alice in Wonderland : a serie[s] of pantomime pictures for grand orchestra"
  And I press "search"
  Then I should get at least 200 results
  And I should get the same number of results as a number search for "Alice in Wonderland a serie[s] of pantomime pictures for grand orchestra"  
  And I should get the same number of results as a number search for "alice wonderland serie[s] pantomime pictures grand orchestra"  

Scenario: FIXME (Jira 683): colon as part of search should be ignored
  Given I am on the home page
  When I fill in "q" with "international encyclopedia of revolution and protest : 1500 to the present"
  And I press "search"
  Then I should get results
  And I should get the same number of results as a number search for "international encyclopedia of revolution and protest 1500 to the present"  

Scenario: Search for unmatched paren as part of query
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "(french horn"
  And I press "search"
  Then I should get results
  And I should get the same number of results as a search for "french horn"
  And I should get the same number of results as a search for "french( horn"
  And I should get the same number of results as a search for "french (horn"
  And I should get the same number of results as a search for "french horn("
  And I should get the same number of results as a search for ")french horn"
  And I should get the same number of results as a search for "french) horn"
  And I should get the same number of results as a search for "french )horn"
  And I should get the same number of results as a search for "french horn)"

Scenario: FIXME: Non-dismax special lone characters should politely return 0 results
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "&"
  And I press "search"
  Then I should get at most 0 results
  # lucene query parsing special chars that are not special to dismax:
  # && || ! ( ) { } [ ] ^ ~ * ? : \
  And I should get the same number of results as a search for "|"
  And I should get the same number of results as a search for "!"
  And I should get the same number of results as a search for "("
  And I should get the same number of results as a search for ")"
  And I should get the same number of results as a search for "{"
  And I should get the same number of results as a search for "}"
  And I should get the same number of results as a search for "["
  And I should get the same number of results as a search for "]"
  And I should get the same number of results as a search for "^"
  And I should get the same number of results as a search for "~"
  And I should get the same number of results as a search for "*"
  And I should get the same number of results as a search for "?"
  And I should get the same number of results as a search for ":"
  And I should get the same number of results as a search for "\"
  # and a semicolon and a period for good measure
  And I should get the same number of results as a search for ";"


# TODO:  period doesn't behave nicely
#  And I should get the same number of results as a search for "."


# TODO: error handling of parsed query leaves much to be desired
# Give Errors
#And I should get the same number of results as a search for "&&"
#And I should get the same number of results as a search for "||"
#When I fill in "q" with "+"
#When I fill in "q" with "-"
#When I fill in "q" with "\""


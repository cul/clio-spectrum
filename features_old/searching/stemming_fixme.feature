@searching, @fixme
Feature: NEEDS IMPROVEMENT: Search Results with Stemming that interferes with optimal results (Stanford)
  In order to get improved search results for stemmed words
  As an end user, when I enter search terms
  I want to see search results that pass the following tests

#  There are two records:  4216963, 4216961  that have the word "search" in the 245, 
# and also have the word "search" in the 880 vernacular 245 field. 
# Because the term appears twice:  in the 245a and the corresponding 880a, these records are 
# appearing first.  I think the solution will be to boost the "regular" instances of fields 
# slightly more than the 880 vernacular instances of the same.
Scenario: FIXME: Query for "search" should not weight 880 fields the same as regular
  Given a SOLR index with Stanford MARC data
  And I go to the catalog page
  When I fill in "q" with "searching"
  And I press "search"
  Then I should get ckey 8243964 before ckey 4216963
  And I should get ckey 394764 before ckey 4216961

Scenario: FIXME:  Stemming of "figurine" should match "figure"
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "figurine"
  And I press "search"
  And I should get the same number of results as a search for "figure"  




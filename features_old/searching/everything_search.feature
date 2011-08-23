@searching
Feature: Everything (Default) Search Result Relevancy (Stanford)
  In order to get fantastic simple search results
  As an end user, when I enter search terms without making other selections
  I want to see results with awesome relevancy, recall, precision

Scenario: Number of results for "buddhism" should be plausible
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "Buddhism"
  And I press "search"
  Then I should get at least 6500 total results

Scenario: Eloaded records code "wb4" from 856x should have plausible results
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "wb4"
  And I press "search"
  # should be same as wb4{856} in socrates
  Then I should get at least 1800 total results
  And I should get at most 2000 total results

Scenario: Eloaded records code "ei4" from 856x should have plausible results
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "ei4"
  And I press "search"
  # should be same as ei4{856} in socrates
  Then I should get at least 2670 total results
  And I should get at most 3000 total results

Scenario: Number of results for "String quartets Parts" and variants should be plausible
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "String quartets Parts"
  And I press "search"
  Then I should get at least 2000 total results
  And I should get the same number of results as a search for "(string Quartets parts)"
  And I should get more results than a search for "\"String Quartets parts\""

Scenario: Expect specific match and non-match for "french beans food scares" without quotes
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "french beans food scares"
  And I press "search"
  Then I should get ckey 7716344 in the first 1 result
  And I should NOT get ckey 6955556 in the results

Scenario: Tricky term: "Two3" - results with title match should be first
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "Two3"
  And I press "search"
  Then I should get ckey 5732752 in the first 1 result
  And I should get the same number of results as a search for "two3"
# TODO: would like to test that default search is not case sensitive
# TODO: FIXME: test for other less relevant results for Two3
# TODO: FIXME: test for non-relevant results for Two3

Scenario: Results with title match should be first (waffle)
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "waffle"
  And I press "search"
  Then I should get ckey 6720427 before ckey 7763651
  And I should get ckey 4535360 before ckey 7763651
  And I should get ckey 2716658 before ckey 6546657
  And I should get ckey 5087572 before ckey 6546657
  
Scenario: Search with very few results  (jill kerr conway)
  Given a SOLR index with Stanford MARC data
  When I go to the home page
  And I fill in "q" with "jill kerr conway"
  And I press "search"
  Then I should get at most 5 results
  And I should get ckey 4735430 in the first 1 result
  
Scenario: Jill K. Conway matching variants / permutation
  Given a SOLR index with Stanford MARC data
  When I go to the home page
  And I fill in "q" with "jill k. conway"
  And I press "search"
  Then I should get ckey 4735430 in the results
  And I should get the same number of results as a search for "jill k conway"
  And I should get the same number of results as a search for "k jill conway"
  
Scenario: "history of the jews by paul johnson"
  Given a SOLR index with Stanford MARC data
  When I go to the home page
  And I fill in "q" with "history of the jews by paul johnson"
  And I press "search"
  Then I should get ckey 1665541 in the first 2 results
  And I should get ckey 3141358 in the first 2 results
  And I should get ckey 1665541 before ckey 6353918
  And I should get ckey 3141358 before ckey 6353918

Scenario: "memoirs of a physician"
  Given a SOLR index with Stanford MARC data
  When I go to the home page
  And I fill in "q" with "memoirs of a physician"
  And I press "search"
  Then I should get ckey 2318407 in the first 2 results
  And I should get ckey 1242605 in the first 2 results

Scenario: Like Titles Should Appear Together In Results
  Given a SOLR index with Stanford MARC data
  When I go to the home page
  And I fill in "q" with "wanderlust"
  And I press "search"
  Then I should get ckey 6974167 and ckey 5757985 within 2 positions of each other
  And I should get ckey 5757985 and ckey 1630776 within 2 positions of each other
  And I should get ckey 4364566 and ckey 4406971 within 1 position of each other

Scenario: "call of the wild"
  Given a SOLR index with Stanford MARC data
  When I go to the home page
  And I fill in "q" with "call of the wild"
  And I press "search"
  And I select "50" from "per_page"
  And I press "per_page_submit"
  Then I should get at least 18 of these ckeys in the first 25 results: "6635999, 2472361, 3240949, 3431568, 4410827, 6763852, 3066683, 3440375, 2228310, 7823673, 5684390, 573747, 573745, 573746, 675590, 7111112, 1363337, 2184693, 1004499"

Scenario: Searches Should Not Be Case Sensitive
  Given a SOLR index with Stanford MARC data
  When I go to the home page
  And I fill in "q" with "harry potter"
  And I press "search"
  Then I should get the same number of results as a search for "Harry Potter"

    
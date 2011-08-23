@searching
Feature: Stemming (Stanford)
  In order to get fantastic search results
  As an end user, when I enter search terms
  I want to see results with awesome relevancy, recall, precision

# See Also:  stemming_fixme.feature

Scenario: Query for "cooking" should have exact word matches before stemmed ones
  Given a SOLR index with Stanford MARC data
  And I go to the catalog page
  When I fill in "q" with "cooking"
  And I press "search"
  Then I should get ckey 4779910 in the first 1 results
  And I should get result titles that contain "cooking" as the first 20 results

Scenario: Query for "modeling" should have exact word matches before stemmed ones
  Given a SOLR index with Stanford MARC data
  And I go to the catalog page
  When I fill in "q" with "modeling"
  And I press "search"
  Then I should get result titles that contain "modeling" as the first 20 results

Scenario: Query for "photographing" should have exact word matches before stemmed ones
  Given a SOLR index with Stanford MARC data
  And I go to the catalog page
  When I fill in "q" with "photographing"
  And I press "search"
  # example of a two word title, starting with query term
  Then I should get ckey 685794 in the first 10 results
  And I should get result titles that contain "photographing" as the first 20 results

Scenario: Query for "arabic" should have exact word matches before stemmed ones
  Given a SOLR index with Stanford MARC data
  And I go to the catalog page
  When I fill in "q" with "arabic"
  And I press "search"
  Then I should get result titles that contain "arabic" as the first 20 results

Scenario: Query for "searching" should have exact word matches before stemmed ones
  Given a SOLR index with Stanford MARC data
  And I go to the catalog page
  When I fill in "q" with "searching"
  And I press "search"
  Then I should get result titles that contain "searching" as the first 20 results
  And I should not get ckey 4216963 in the results
  And I should not get ckey 4216961 in the results

Scenario: Stemming: Austen also gives Austenland, Austen's 
  Given a SOLR index with Stanford MARC data
  And I go to the catalog page
  When I fill in "q" with "Austen"
  And I press "search"
  And I select "title" from "sort"
  And I press "sort_submit"
  And I select "100" from "per_page"
  And I press "per_page_submit" 
  # Austen
  Then I should get ckey 3393754 before ckey 6865948
  # Austenland
  And I should get ckey 6865948 before ckey 5847283
  # Austen's
  And I should get ckey 5847283 in the results

Scenario: tattoo, tattoos, tattoed
  Given a SOLR index with Stanford MARC data
  And I go to the catalog page
  When I fill in "q" with "tattoo"
  And I press "search"
  Then I should get the same number of results as a search for "tattoos"
  And I should get the same number of results as a search for "tattooed"

Scenario: Latin Stemming  ae and a should be equivalent
  Given a SOLR index with Stanford MARC data
  And I go to the catalog page
  When I fill in "q" with "musicae disciplinae"
  And I press "search"
  Then I should get the same number of results as a search for "musica disciplina"

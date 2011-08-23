@searching, @fixme
Feature: Journal Title Search Result Relevancy  (Stanford)
  As an end user, when I do a journal title search and select format facet value "journal/periodical"
  I want to see search results with awesome relevancy, recall, precision

  Scenario: "Times of London" - common words ... as a phrase  (it's actually a newspaper ...)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"Times of London\""
    And I select "Title" from "search_field"
    And I press "search"
    #  And I follow "Journal/Periodical"   # it's also a newspaper!!!
    # ISSN:  0140-0460
    And I should get at least 1 of these ckeys in the first 3 results: "3352297, 425948, 425951"
    And I should get at least 3 of these ckeys in the first 10 results: "3352297, 425948, 425951"

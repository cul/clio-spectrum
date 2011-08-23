@searching
Feature: Journal Title Search Result Relevancy  (Stanford)
  As an end user, when I do a journal title search and select format facet value "journal/periodical"
  I want to see search results with awesome relevancy, recall, precision

  Scenario: "Nature"
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "nature"
    And I select "Title" from "search_field"
    And I press "search"
    And I follow "Journal/Periodical"
    Then I should get at most 1000 results
    # ISSN:   0028-0836,   Nature [print/digital].  and  Nature; international journal of science
    And I should get at least 1 of these ckeys in the first 3 results: "3195844, 8630013"
    And I should get at least 2 of these ckeys in the first 5 results: "3195844, 8630013"
    
  Scenario: "The Nation" - stemming (National, etc.)
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "The Nation"
    And I select "Title" from "search_field"
    And I press "search"
    And I follow "Journal/Periodical"
    Then I should get at most 7650 results
    # ISSN:  0027-8378
    And I should get at least 1 of these ckeys in the first 3 results: "7557007, 464445, 497417, 3448713"
    And I should get at least 2 of these ckeys in the first 5 results: "7557007, 464445, 497417, 3448713"

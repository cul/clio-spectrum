@searching
Feature: Facet Selection Result Relevancy (Stanford)
  In order to get fantastic results 
  As an end user, when I select facets
  I want to see search results with awesome relevancy, recall, precision

  Scenario: Landing Page Call Number Facet Values should be Alphabetical
    Given a SOLR index with Stanford MARC data
    When I go to the home page
    Then I should see "A - " before "B - "
    And I should see "D -" before "Dewey"
  
  Scenario: LC Call Number: Music
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "caterpillars"
    And I press "search"
    And I follow "M - Music"
    # Call number was changed and is not being viewed as an M for the time being
    # Then I should get ckey 287900 in the first 1 result
    And I should get ckey 294924 in the results
    And I should get ckey 5637322 in the results
  
  Scenario: Format Books
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "French miniatures"
    And I press "search"
    And I follow "Book"
    Then I should get at least 120 total results
    And I should get at least 1 of these ckeys in the first 1 results: "728793, 2043360"
    And I should get at least 5 of these ckeys in the first 20 results: "728793, 2043360, 20084, 2147642, 1067894, 2455851"

  Scenario: Format Books
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "French miniatures"
    And I press "search"
    And I follow "Book"
    Then I should get at least 120 total results
    And I should get at least 1 of these ckeys in the first 1 results: "728793, 2043360"
    And I should get at least 5 of these ckeys in the first 20 results: "728793, 2043360, 20084, 2147642, 1067894, 2455851"
    
  Scenario: No Facet Values of "Unknown"
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    Then I should not see "Unknown"
    When I press "search"
    Then I should not see "Unknown"

  Scenario: Trailing Period Stripped from Facet Values
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "pyramids"
    And I press "search"
    Then I should see "Pyramids"
    And I should not see "Pyramids."
    
  Scenario: Bogus Lane Topics, like "nomesh", and stuff from 655a, should not be facet values
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I follow "Lane (Medical)"
    Then I should not see "nomesh"
    And I should not see "Internet Resource"
    And I should not see "Fulltext"
    
  Scenario: Facets for Jane Austen Everything Search, then Author Facet, Should Have Videos
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in "q" with "jane austen"
    And I press "search"
    Then I follow "Austen, Jane, 1775-1817"
    Then I should see "Video"

  Scenario: Author Facet Should Include 700 Fields
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"decentralization and school improvement\""
    And I press "search"
    Then I should see "Carnoy, Martin"
    And I should see "Hannaway, Jane"

  Scenario: Facets with Diacritics should work - é
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I follow "Music - Score"
    And I follow "Organ music"
    And I follow "Franck, César, 1822-1890"
    Then I should get at least 15 results

  Scenario: Facets with Diacritics should work - ĭ
    Given a SOLR index with Stanford MARC data
    And I go to the home page
    When I fill in the search box with "\"russian children's literature collection\""
    And I press "search"
    And I follow "Chukovskiĭ, Korneĭ, 1882-1969"
    Then I should get at least 40 total results


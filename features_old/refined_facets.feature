Feature: Hierarchical Facets 
  As a user
  In order to enjoy the benefits of hierarchical facets
  I want to see hierarchical facets displayed clearly and usefully
  
  Scenario: No Refinement Displayed When Value NOT Selected from Hierarchical Facet
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    Then I should not see "Refine"

  Scenario: No Refinement Displayed When Value Selected from non-Hierarchical Facet
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "Book"
    Then I should not see "Refine Format"

  Scenario: Refinement Displayed When Value Selected from Hierarchical Facet
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "Dewey Classification"
    Then I should see "Refine"

  Scenario: Only The Next Level of Refinement Displayed, not All Levels of Refinement
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "Dewey Classification"
    Then I should see "Refine" exactly 2 times

# can't think of a way to test this except yucky xpath
#  Scenario: No "more" link Displayed For Level At Selected Value of Hierarchical Facet
#  Scenario: Refinement Facet Has Same Structure As Regular Facet (links, more link, etc.)

  Scenario: Selecting a Call Number Suppresses Display of Additional Facet Values at Same Level
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "A - General Works"
    Then I should not see "Dewey Classification ("
    And I should not see "Government Document ("

# Note: Refinement level facet can display values out of the hierarchy (from add'l items with diff call numbers)

  Scenario: LC Alpha Refinement Displayed when an LC Letter is Selected from Call Number Facet
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "A - General Works"
    Then I should see "AM - Museums ("
    And I should not see "AM101 ("

  Scenario: LC B4 Cutter Refinement Displayed when LC Alpha Value is Selected
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "A - General Works"
    And I follow "AM - Museums"
    And I should see "AM101 ("
    And I should not see "AB -"

  Scenario: Dewey 1 Digit Refinement Displayed when Dewey is Selected from Call Number Facet
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "Dewey Classification"
    Then I should see "000s"
    And I should not see "010s"

  Scenario: Dewey 2 Digit Refinement Displayed when Dewey 1 Digit Value is Selected
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "Dewey Classification"
    And I follow "300s - Social Sciences"
    Then I should see "330s"
    And I should not see "330.1"
    And I should not see "440s"
  
  Scenario: Dewey B4 Cutter Refinement Displayed when Dewey 2 Digit Value is Selected
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "Dewey Classification"
    And I follow "300s - Social Sciences"
    And I follow "330s - Economics"
    Then I should see "330.1"
    And I should not see "310s"
    And I should not see "330.11111111"
  
  Scenario: Gov Doc Refinement Display when Gov Doc is Selected from Call Number Facet
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "Government Document"
    Then I should see "California ("
    And I should not see "Dewey Classification ("


  Scenario: Pub Year Refinement Display when Pub Group Date is Selected
    Given a SOLR index with Stanford MARC data
    When I am on the home page
    And I follow "Book"
    And I follow "Last 10 Years"
    Then I should see "2009 ("
    And I should not see "1995 ("

Feature: Bad 999
  In order to make sure that our bad 999s aren't causing an error
  As a user
  I want to not get an error
  
  Scenario: Bucky Papers
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "4332640"
    Then I should see "Buckminster Fuller papers"
    
  Scenario: Ginsberg papers
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "4084385"
    Then I should see "Allen Ginsberg papers"
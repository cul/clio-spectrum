Feature: Various Document IDs
  As a user
  In order to verify that the object_id is not being used in place of the document id (ckey)
  I want to see all known instances of ID and verify that it is a ckey and not an object_id

  Scenario: Tech Details
    Given a SOLR index with Stanford MARC data
    When I am on the show page for "7835082"
    Then I should see a link element with "7835082" inside the href and "Compare in Socrates" as the link text
    And I should see a link element with "7835082" inside the href and "Cite This" as the link text
    And I should see a link element with "7835082" inside the href and "Text" as the link text
    And I should see a link element with "7835082" inside the href and "Email" as the link text
    And I should see a link element with "7835082" inside the href and "RefWorks" as the link text
    And I should see a link element with "7835082" inside the href and "EndNote" as the link text
@articles @360link
Feature: Handle 360link api
  In order to keep a consistent look and experience for users
  we will use the 360Link API to display elinks rather than Serial Solutions' page

  #Scenario: Displaying book items
    #When I search "articles" for "stanley jacobson neuroanatomy neuroscientist"
    #And I click on the "1st" result
    #And I look at the item level view
    #Then the "Source" field should include "Neuroanatomy for the"
    #And the holdings have the database "SpringerLink ebooks" with links "Book"

  Scenario: Displaying journal articles
    When I search "articles" for "raising alexandria colt george howe"
    And I click on the "1st" result
    And I look at the item level view
    Then the "Source" field should include "Life"
    And the holdings have the database "Academic Search Complete" with links "Article, Journal"

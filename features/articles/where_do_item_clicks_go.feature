@wip @summon @articles @360link
Feature: Correct 360link routing
  In order to send users to the right resource
  CLIO should intelligently determine whether to send a user
  to an item-level e-link view, or directly to a resource
 
  Scenario: Proquest search
    When I search "articles" for "transference Ojibwe"
    And looking at the "1st" result 
    Then the title should include "Ojibwe into English contexts"
    And the "Format" field should include "Full Text Available"
    And the link should be local

  Scenario: Citation only
    When I search "articles" for "amazonia petit p"
    And looking at the "1st" result
    Then the title should include "Amazonia"
    And the "Format" field should include "Journal"
    And the "Format" field should include "Citation"
    And the link should not be local
    #When I click on the "1st" result
    #Then the url should include "webofknowledge.com"

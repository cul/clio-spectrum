@summon @articles @360link
Feature: 360Link display
  In order to display item-level views
  in a method consistent with the rest of Spectrum
  we use the 360Link API to pull information.

  Scenario: 
    When I go to the articles page
    And I search articles with "chris beeley psychopath emotion brain"
    Then result 1 should include "The Psychopath: Emotion and the Brain" 

@academiccommons
Feature: Handles on Academic Commons 
  In order to allow people to permanently link to academic commons items
  CLIOBeta should display permanent URLs

  Scenario: Displaying handles
    When I search "academic commons" for "sachs poland privatization"
    And looking at the "1st" result
    Then the "Handle" field should include "hdl.handle.net"
    And the title should include "Privatization in Poland"


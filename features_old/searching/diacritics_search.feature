@searching
Feature: Diacritics and Searching (Stanford)
  In order to get correct search results for words with diacritics
  As an end user, when I enter search terms with or without diacritics
  I want to see the same search results 
   
Scenario: Acute Accent
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "étude"
  And I press "search"
  Then I should get ckey 466512 in the results
  And I should get ckey 5747443 in the results
  And I should get the same number of results as a search for "etude"

Scenario: Umlaut
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "Ränsch-Trill"
  And I press "search"
  Then I should get ckey 2911735 in the results
  And I should get the same number of results as a search for "Ransch-Trill"
  
Scenario: Macron diacritic
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "Rekishi yūgaku"
  And I press "search"
  Then I should get ckey 5338009 in the results
  And I should get the same number of results as a search for "Rekishi yugaku"

Scenario: Polish S diacritic
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "Ṡpiewy polskie"
  And I press "search"
  Then I should get ckey 2209396 in the results
  And I should get ckey 307686 in the results
  And I should get the same number of results as a search for "Spiewy polskie"
  
Scenario: Polish diacritics
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "Żułkoós"
  And I press "search"
  Then I should get ckey 1885035 in the results
  And I should get the same number of results as a search for "Zulkoos"

Scenario: Hebrew transliteration diacritics
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "le-Ḥayim"
  And I press "search"
  Then I should get ckey 6312584 in the results
  And I should get ckey 3503974 in the results
  And I should get the same number of results as a search for "le-hayim"

Scenario: Hebrew script diacritics
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "סֶגוֹל"
  And I press "search"
  Then I should get ckey 5666705 in the results
  And I should get the same number of results as a search for "סגול"

Scenario: Arabic script diacritics
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "دَ"
  And I press "search"
# sent email to John Eilts 2010-08-22  for better test search examples
#  Then I should get ckey 4776517 in the results
  And I should get the same number of results as a search for "د"

Scenario: Arabic script letter alif with diacritics
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "أ"
  And I press "search"
  And I should get the same number of results as a search for "أ"
  And I should get the same number of results as a search for "ـأ"
  And I should get the same number of results as a search for "أ"

Scenario: Greek script diacritics
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "τῆς"
  And I press "search"
  Then I should get ckey 7719950 in the results
  And I should get the same number of results as a search for "της"

Scenario: Ae ligature diacritics - searching
  Given a SOLR index with Stanford MARC data
  And I go to the home page
  When I fill in "q" with "Æon"
  And I press "search"
  Then I should get ckey 6197318 in the results
  And I should get ckey 6628532 in the results
  And I should get the same number of results as a search for "aeon"

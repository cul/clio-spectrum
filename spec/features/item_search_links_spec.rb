# encoding: utf-8


require 'spec_helper'

describe "Search links in item display should work", :focus => false do

  it "including links with diacritics and trailing punctuation" do
    # setup UTF-8 Decomposed form string constants for our various targets
    # the title:
    mqis_decomposed = 'Mādhā qāla al-Imām al-Shaʻrāwī'.mb_chars.normalize(:d)
    # the "also listed under" name:
    mhmm_decomposed = 'Mazrūʻah, Ḥātim Muḥammad Manṣūr.'.mb_chars.normalize(:d)
    # the author:
    smm_decomposed = 'Shaʻrāwī, Muḥammad Mutawallī.'.mb_chars.normalize(:d)

    # visit this specific item
    visit catalog_path('10172954')

    # follow the "Also Listed Under" linked name, should get to search results page
    click_link(mhmm_decomposed)
    page.should have_css(".result", :count => 1)

    # click the title on the search-results page, snoudl get to the item-detail page again
    click_link(mqis_decomposed)

    # follow the "Author" linked name, should get to search results page, with many items
    click_link(smm_decomposed)

    page.should have_css('.result')
    page.should_not have_text('No results found')
  end

end

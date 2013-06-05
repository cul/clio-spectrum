# encoding: utf-8


require 'spec_helper'

describe "Search links in item display should work", :focus => false do

  it "including links with diacritics and trailing punctuation" do

    pending "BROKEN UTF8 HANDLING"
    # visit this specific item
    visit catalog_path('10172954')
    # page.save_and_open_page # debug
    page.should have_text('Also Listed Under')
    page.should have_text('Mu')
    page.should have_content("Mu\u1E25ammad")

    # follow the "Also Listed Under" linked name, should get to search results page
    page.should have_link("Mazrūʻah, Ḥātim Muḥammad Manṣūr.", :href=>"/catalog?f%5Bauthor_facet%5D%5B%5D=Mazru%CC%84%CA%BBah%2C+H%CC%A3a%CC%84tim+Muh%CC%A3ammad+Mans%CC%A3u%CC%84r")
    click_link('Mazrūʻah, Ḥātim Muḥammad Manṣūr.')
    page.should have_css(".result", :count => 1)

    # click back, to the same item again.
    click_link('Mādhā qāla al-Imām al-Shaʻrāwī fī tafsīrihi ʻan taḥkīm al-sharīʻah wa-taṭbīqihā?')

    # follow the "Author" linked name, should get to search results page
    page.should have_link('Shaʻrāwī, Muḥammad Mutawallī.', :href=>"/catalog?f%5Bauthor_facet%5D%5B%5D=Sha%CA%BBra%CC%84wi%CC%84%2C+Muh%CC%A3ammad+Mutawalli%CC%84")
    click_link('Shaʻrāwī, Muḥammad Mutawallī.')

    page.should have_css('.result')
    page.should_not have_text('No results found')
  end

end

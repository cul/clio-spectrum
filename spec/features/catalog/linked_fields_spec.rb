# encoding: utf-8


require 'spec_helper'

describe "Linked field-values in single-item display should work", :focus => false do

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

  # NEXT-526 - clicking on hyperlinked editor's name returns null result
  it "including RDA roles, such as 'editor'" do
    test_bib = '9720272'
    test_title = '50 Jahre Schaubühne 1962-2012'.mb_chars.normalize(:d)
    test_link = 'Schitthelm, Jürgen, editor.'.mb_chars.normalize(:d)

    # pull up the specific record, by bib key
    visit catalog_path(test_bib)
    page.should have_text(test_title)

    # follow the "Also Listed Under" hyperlinked field value
    click_link(test_link)

    # Should be on the item-results page, which should include at least the item just visited
    page.should have_css('#documents')
    page.should have_text('You searched for:')
    page.should_not have_text('No results')
    page.should have_link(test_title, :href => "/catalog/#{test_bib}")
  end

  # NEXT-546 - author link is not finding all the other books by this author
  it "including RDA roles, such as 'author'" do
    test_bib = '9398081'
    test_title = 'The long and short of it'
    test_link = 'Morson, Gary Saul, 1948-, author.'

    # pull up the specific record, by bib key
    visit catalog_path(test_bib)
    page.should have_text(test_title)

    # follow the "Also Listed Under" hyperlinked field value
    click_link(test_link)

    # Should be on the item-results page, which should include at least the item just visited
    page.should have_css('#documents')
    page.should have_text('You searched for:')
    page.should_not have_text('No results')
    page.should_not have_text('1 of 1')
    page.should have_link(test_title, :href => "/catalog/#{test_bib}")
  end

  # NEXT-560 - ampersands in author search cause searches to fail
  it "including ampersands and trailing punctuation" do
    test_bib = '787284'
    test_title = '180 East 73rd Street Building, Borough of Manhattan'
    test_link = 'William Schickel & Co.'

    # pull up the specific record, by bib key
    visit catalog_path(test_bib)
    page.should have_text(test_title)

    # follow the "Also Listed Under" hyperlinked field value
    click_link(test_link)

    # Should be on the item-results page, which should include at least the item just visited
    page.should have_css('#documents')
    page.should have_text('You searched for:')
    page.should_not have_text('No results')
    page.should_not have_text('1 of 1')
    page.should have_link(test_title, :href => "/catalog/#{test_bib}")
  end

  # NEXT-561 - Some names with diacritics continue to fail in CLIO Beta
  it "including ampersands and trailing punctuation" do
    test_bib = '7030828'
    test_title = 'Iranian DVD oral history collection'
    test_link_array = [
      'Aḥmadī, Ḥamīd.'.mb_chars.normalize(:d),
      'Aʻlāmī, Shahnāz.'.mb_chars.normalize(:d),
      'Darvīshʹpūr, Mihrdād.'.mb_chars.normalize(:d),
      'Jahānʹshāhlū Afshār, Nuṣrat Allāh.'.mb_chars.normalize(:d),
      'Banī Ṣadr, Abū al-Ḥasan.'.mb_chars.normalize(:d),
      'Ibrāhīmʹzādah, Rāz̤iyah.'.mb_chars.normalize(:d),
    ]

    # pull up the specific record, by bib key
    visit catalog_path(test_bib)
    page.should have_text(test_title)


    test_link_array.each do |test_link|
      # follow the "Also Listed Under" hyperlinked field value
      click_link(test_link)

      # Should be on the item-results page, which should include at least the item just visited
      page.should have_css('#documents')
      page.should have_text('You searched for:')
      page.should_not have_text('No results')
      page.should_not have_text('1 of 1')
      page.should have_link(test_title, :href => "/catalog/#{test_bib}")

      # Now, follow the link, should get back to item-detail page
      click_link(test_title)
      page.should have_text(test_title)
    end
  end

  # NEXT-771 - Author link is not finding other resource by the same author
  it "including RDA roles, such as 'author'" do
    test_bib = '10288244'
    test_title = 'Islamic books'
    test_link = 'Riedel, Dagmar A., author.'

    # pull up the specific record, by bib key
    visit catalog_path(test_bib)
    page.should have_text(test_title)

    # follow the "Also Listed Under" hyperlinked field value
    click_link(test_link)

    # Should be on the item-results page, which should include at least the item just visited
    page.should have_css('#documents')
    page.should have_text('You searched for:')
    page.should_not have_text('No results')
    page.should_not have_text('1 of 1')
    page.should have_link(test_title, :href => "/catalog/#{test_bib}")
  end

  # NEXT-862 - author search/facet isn't working
  it "including trailing punctuation" do
    test_bib = '327686'
    test_title = 'The family in the Soviet system'
    test_link = 'Juviler, Peter H.'

    # pull up the specific record, by bib key
    visit catalog_path(test_bib)
    page.should have_text(test_title)

    # follow the "Also Listed Under" hyperlinked field value
    click_link(test_link)

    # Should be on the item-results page, which should include at least the item just visited
    page.should have_css('#documents')
    page.should have_text('You searched for:')
    page.should_not have_text('No results')
    page.should_not have_text('1 of 1')
    page.should have_link(test_title, :href => "/catalog/#{test_bib}")
  end

end

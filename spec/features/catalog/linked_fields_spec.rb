# encoding: utf-8

require 'spec_helper'

describe 'Linked field-values in single-item display', focus: false do

  it 'should work for links with diacritics and trailing punctuation' do
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
    page.should have_css('.result', count: 1)

    # click the title on the search-results page, snoudl get to the item-detail page again
    click_link(mqis_decomposed)

    # follow the "Author" linked name, should get to search results page, with many items
    click_link(smm_decomposed)

    page.should have_css('.result')
    page.should_not have_text('No results found')
  end

  # NEXT-526 - clicking on hyperlinked editor's name returns null result
  it "should work for RDA roles, such as 'editor'" do
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
    page.should have_link(test_title, href: "/catalog/#{test_bib}")
  end

  # NEXT-546 - author link is not finding all the other books by this author
  it "should work for RDA roles, such as 'author'" do
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
    page.should have_link(test_title, href: "/catalog/#{test_bib}")
  end

  # NEXT-560 - ampersands in author search cause searches to fail
  it 'should work with ampersands and trailing punctuation' do
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
    page.should have_link(test_title, href: "/catalog/#{test_bib}")
  end

  # NEXT-561 - Some names with diacritics continue to fail in CLIO Beta
  it 'should work with ampersands and trailing punctuation' do
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
      page.should have_link(test_title, href: "/catalog/#{test_bib}")

      # Now, follow the link, should get back to item-detail page
      click_link(test_title)
      page.should have_text(test_title)
    end
  end

  # NEXT-771 - Author link is not finding other resource by the same author
  it "should work for RDA roles, such as 'author'" do
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
    page.should have_link(test_title, href: "/catalog/#{test_bib}")
  end

  # NEXT-862 - author search/facet isn't working
  it 'should work with trailing punctuation' do
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
    page.should have_link(test_title, href: "/catalog/#{test_bib}")
  end

  # NEXT-1011 - Inconsistent search results from series links.
  it "should support linking to Series Title" do
    visit catalog_path '9646827'
    page.should have_text "Lo specchio acceso : narrativa italiana"
    # field-label, white-space, field-value
    page.should have_text "Series Collezione Confronti/consensi ; 15."

    click_link "Collezione Confronti/consensi ; 15."
    page.should have_text "You searched for: Series: Collezione Confronti/consensi"
    page.should_not have_text('No results')
    page.should_not have_text('1 of 5')
    find('#documents').should have_text 'Lo specchio acceso : narrativa italiana'
  end

  # NEXT-1066 - Series link on this record does not retrieve other records in CLIO.
  it "should support Series links with apostrophe-like characters" do
    visit catalog_path(2754188)
    page.should have_text "Palestine > History"
    page.should have_text "Jerusalem, Magnes Press, Hebrew University"

    # field-label, white-space, field-value
    series_decomposed = 'Sidrat meḥḳarim ʻal shem Uriʼel Hed.'.mb_chars.normalize(:d)
    page.should have_text(series_decomposed)

    click_link(series_decomposed)
    page.should have_text "You searched for: Series: #{series_decomposed}"
    page.should_not have_text('No results')
    page.should have_text('1 - 4 of 4')
    # list out four title snippets to look for...
    find('#documents').should have_text 'Hityashvut ha-Germanim'
    find('#documents').should have_text '18th century; patterns of government'
    find('#documents').should have_text '1918-1929'
    title_4 = 'ha-ʻUlama u-veʻayot dat ba-ʻolam ha-Muslemi : meḥḳarim le-zekher Uriʾel Hed'
    find('#documents').should have_text title_4.mb_chars.normalize(:d)
  end

  # NEXT-1107 - Pre-composed characters in facets
  # These two bib records (10322893, 10551688) encode the name Cipa differently,
  # both should link correctly, and "author" facet should be combined.
  it "should work equivalently with pre-composed or de-composed unicode forms" do
    visit catalog_path(10322893)
    # "Also Listed Under Çıpa, H. Erdem, 1971-"
    click_link('H. Erdem, 1971')
    page.should have_text('1 - 2 of 2')
    within('#facet-author li', text: 'Erdem') do
      find('.facet-label').should have_text "Çıpa, H. Erdem, 1971"
      find('.facet-count').should have_text "2"
    end

    visit catalog_path(10551688)
    # "Also Listed Under Çıpa, H. Erdem, 1971-"
    click_link('H. Erdem, 1971')
    page.should have_text('1 - 2 of 2')
    within('#facet-author li', text: 'Erdem') do
      find('.facet-label').should have_text "Çıpa, H. Erdem, 1971"
      find('.facet-count').should have_text "2"
    end
  end
end



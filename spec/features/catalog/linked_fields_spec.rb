# encoding: utf-8

require 'spec_helper'

describe 'Linked field-values in single-item display' do
  it 'should work for links with diacritics and trailing punctuation' do
    # setup UTF-8 Precomposed form string constants for our various targets
    # the title:
    mqis_precomposed = 'Mādhā qāla al-Imām al-Shaʻrāwī'.mb_chars.normalize(:c)
    # the "also listed under" name:
    mhmm_precomposed = 'Mazrūʻah, Ḥātim Muḥammad Manṣūr.'.mb_chars.normalize(:c)
    # the author:
    smm_precomposed = 'Shaʻrāwī, Muḥammad Mutawallī.'.mb_chars.normalize(:c)

    # visit this specific item
    visit solr_document_path('10172954')

    # follow the "Also Listed Under" linked name, should get to search results page
    click_link(mhmm_precomposed)
    expect(page).to have_css('.result', count: 2)

    # click the title on the search-results page, snoudl get to the item-detail page again
    click_link(mqis_precomposed)

    # follow the "Author" linked name, should get to search results page, with many items
    click_link(smm_precomposed)

    expect(page).to have_css('.result')
    expect(page).to_not have_text('No results found')
  end

  # NEXT-526 - clicking on hyperlinked editor's name returns null result
  it "should work for RDA roles, such as 'editor'" do
    test_bib = '9720272'
    test_title = '50 Jahre Schaubühne 1962-2012'.mb_chars.normalize(:c)
    test_link = 'Schitthelm, Jürgen, editor.'.mb_chars.normalize(:c)

    # pull up the specific record, by bib key
    visit solr_document_path(test_bib)
    expect(page).to have_text(test_title)

    # follow the "Also Listed Under" hyperlinked field value
    click_link(test_link)

    # Should be on the item-results page, which should include at least the item just visited
    expect(page).to have_css('#documents')
    expect(page).to have_text('You searched for:')
    expect(page).to_not have_text('No results')
    expect(page).to have_link(test_title, href: "/catalog/#{test_bib}")
  end

  # NEXT-546 - author link is not finding all the other books by this author
  it "should work for RDA roles, such as 'author' (Morson)" do
    test_bib = '9398081'
    test_title = 'The long and short of it'
    # test_link = 'Morson, Gary Saul, 1948-, author.'
    test_link = 'Morson, Gary Saul, 1948- author.'

    # pull up the specific record, by bib key
    visit solr_document_path(test_bib)
    expect(page).to have_text(test_title)

    # follow the "Also Listed Under" hyperlinked field value
    click_link(test_link)

    # Should be on the item-results page, which should include at least the item just visited
    expect(page).to have_css('#documents')
    expect(page).to have_text('You searched for:')
    expect(page).to_not have_text('No results')
    expect(page).to_not have_text('1 of 1')
    expect(page).to have_link(test_title, href: "/catalog/#{test_bib}")
  end

  # NEXT-560 - ampersands in author search cause searches to fail
  it 'should work with ampersands and trailing punctuation' do
    test_bib = '787284'
    test_title = '180 East 73rd Street Building, Borough of Manhattan'
    test_link = 'William Schickel & Co.'

    # pull up the specific record, by bib key
    visit solr_document_path(test_bib)
    expect(page).to have_text(test_title)

    # follow the "Also Listed Under" hyperlinked field value
    click_link(test_link)

    # Should be on the item-results page, which should include at least the item just visited
    expect(page).to have_css('#documents')
    expect(page).to have_text('You searched for:')
    expect(page).to_not have_text('No results')
    expect(page).to_not have_text('1 of 1')
    expect(page).to have_link(test_title, href: "/catalog/#{test_bib}")
  end

  # NEXT-561 - Some names with diacritics continue to fail in CLIO
  it 'work with diacritics' do
    test_bib = '7030828'
    test_title = 'Iranian DVD oral history collection'
    test_link_array = [
      'Aʻlāmī, Shahnāz.'.mb_chars.normalize(:c),
      'Darvīshʹpūr, Mihrdād.'.mb_chars.normalize(:c),
      'Jahānʹshāhlū Afshār, Nuṣrat Allāh.'.mb_chars.normalize(:c),
      'Banī Ṣadr, Abū al-Ḥasan.'.mb_chars.normalize(:c),
      'Ibrāhīmʹzādah, Rāz̤iyah.'.mb_chars.normalize(:c)
    ]

    # pull up the specific record, by bib key
    visit solr_document_path(test_bib)
    expect(page).to have_text(test_title)

    test_link_array.each do |test_link|
      # follow the "Also Listed Under" hyperlinked field value
      click_link(test_link)

      # More results per page so that below tests works
      click_link 'Display Options'
      click_link '50 per page'

      # Should be on the item-results page, which should include at least the item just visited
      expect(page).to have_css('#documents')
      expect(page).to have_text('You searched for:')
      expect(page).to_not have_text('No results')
      expect(page).to_not have_text('1 of 1')
      expect(page).to have_link(test_title, href: "/catalog/#{test_bib}")

      # Now, follow the link, should get back to item-detail page
      click_link(test_title)
      expect(page).to have_text(test_title)
    end
  end

  # NEXT-771 - Author link is not finding other resource by the same author
  it "should work for RDA roles, such as 'author' (Riedel)" do
    test_bib = '10288244'
    test_title = 'Islamic books'
    test_link = 'Riedel, Dagmar A., author.'

    # pull up the specific record, by bib key
    visit solr_document_path(test_bib)
    expect(page).to have_text(test_title)

    # follow the "Also Listed Under" hyperlinked field value
    click_link(test_link)

    # Should be on the item-results page, which should include at least the item just visited
    expect(page).to have_css('#documents')
    expect(page).to have_text('You searched for:')
    expect(page).to_not have_text('No results')
    expect(page).to_not have_text('1 of 1')
    expect(page).to have_link(test_title, href: "/catalog/#{test_bib}")
  end

  # NEXT-862 - author search/facet isn't working
  it 'should work with trailing punctuation' do
    test_bib = '327686'
    test_title = 'The family in the Soviet system'
    test_link = 'Juviler, Peter H.'

    # pull up the specific record, by bib key
    visit solr_document_path(test_bib)
    expect(page).to have_text(test_title)

    # follow the "Also Listed Under" hyperlinked field value
    click_link(test_link)

    # Should be on the item-results page, which should include at least the item just visited
    expect(page).to have_css('#documents')
    expect(page).to have_text('You searched for:')
    expect(page).to_not have_text('No results')
    expect(page).to_not have_text('1 of 1')
    expect(page).to have_link(test_title, href: "/catalog/#{test_bib}")
  end

  # NEXT-1011 - Inconsistent search results from series links.
  it 'should support linking to Series Title' do
    visit solr_document_path '9646827'
    expect(page).to have_text 'Lo specchio acceso : narrativa italiana'
    # field-label, white-space, field-value
    expect(page).to have_text 'Series Collezione Confronti/consensi ; 15.'

    click_link 'Collezione Confronti/consensi ; 15.'
    expect(find('.constraints-container')).to have_text('Collezione Confronti/consensi')
    expect(page).to_not have_text('No results')
    expect(page).to_not have_text('1 of 5')
    expect(find('#documents')).to have_text 'Lo specchio acceso : narrativa italiana'
  end

  # NEXT-1066 - Series link on this record does not retrieve other records in CLIO.
  it 'should support Series links with apostrophe-like characters' do
    visit solr_document_path(2754188)
    expect(page).to have_text 'Palestine > History'
    expect(page).to have_text 'Jerusalem : Magnes Press, Hebrew University'

    # field-label, white-space, field-value
    series_decomposed = 'Sidrat meḥḳarim ʻal shem Uriʼel Hed.'.mb_chars.normalize(:c)
    expect(page).to have_text(series_decomposed)

    click_link(series_decomposed)
    expect(find('.constraints-container')).to have_text(series_decomposed)
    expect(page).to_not have_text('No results')
    expect(page).to have_text('1 - 5 of 5')
    # list out four title snippets to look for...
    expect(find('#documents')).to have_text 'Hityashvut ha-Germanim'
    expect(find('#documents')).to have_text '18th century ; patterns of government'
    expect(find('#documents')).to have_text '1918-1929'
    # title_4 = 'ha-ʻUlama u-veʻayot dat ba-ʻolam ha-Muslemi : meḥḳarim le-zekher Uriʾel Hed'
    title_4 = 'ha-ʻUlama u-veʻayot dat ba-ʻolam ha-Muslemi : meḥḳarim le-zekher Uriʼel Hed' 
    expect(find('#documents')).to have_text title_4.mb_chars.normalize(:c)
  end

  # NEXT-1107 - Pre-composed characters in facets
  # These two bib records (10322893, 10551688) encode the name Cipa differently,
  # both should link correctly, and "author" facet should be combined.
  it 'should work equivalently with pre-composed or de-composed unicode forms' do
    
    cipa_c = 'Çıpa, H. Erdem, 1971'.mb_chars.normalize(:c)
    
    visit solr_document_path(10322893)
    # "Also Listed Under Çıpa, H. Erdem, 1971-"
    click_link('H. Erdem, 1971')
    expect(find('.index_toolbar')).to have_text('1 - 9  of 9')
    within('#facet-author li', text: 'Erdem') do
      expect(find('.facet-label')).to have_text cipa_c
      expect(find('.facet-count')).to have_text '9'
    end

    visit solr_document_path(10551688)
    # "Also Listed Under Çıpa, H. Erdem, 1971-"
    click_link('H. Erdem, 1971')
    expect(find('.index_toolbar')).to have_text('1 - 9  of 9')
    within('#facet-author li', text: 'Erdem') do
      expect(find('.facet-label')).to have_text cipa_c
      expect(find('.facet-count')).to have_text '9'
    end
  end

  # NEXT-1317 - Incorrect search results for series with parenthesis.
  it 'should handle parens within series title' do
    target = 'Monograph (British Institute of Archaeology at Ankara)'
    visit solr_document_path(10904345)
    # Click a series with parenthesized words...
    click_link(target)
    expect(find('.constraints-container')).to have_text(target)

    page_entries = find('.page_links .page_entries').text
    # page_entries should be something like "1 - 25 of 37"
    shown, of, total = page_entries.partition(/ of /)
    expect(total.to_i).to be < 80
  end
end

require 'spec_helper'

describe 'QuickSearch landing page' do
  # NEXT-612 - Quick search page doesn't let you start over
  it "should have a 'Start Over' link", :js do
    visit quicksearch_index_path('q' => 'asia')
    expect(page).to have_css('.result_set', count: 5)
    expect(page).to have_css('.nested_result_set', count: 5)

    all('.result_set').each do |result_set|
      expect(result_set).to have_css('.result')
    end

    expect(find('.landing_across')).to have_text('Start Over')
    within('.landing_across') do
      click_link('Start Over')
    end

    # Verify that we're now on the landing page
    expect(page).to_not have_css('.result_set')
    expect(page).to have_text('Quicksearch performs a combined search of')
  end

  # NEXT-1026 - Clicking 'All Results' for Libraries Website
  # from Quicksearch shows an XML file
  # NEXT-1027 - Relabel 'All #### results' on Quicksearch

  # *** CATALOG ***
  it 'should link to Catalog results correctly', js: true, focus: false do
    visit quicksearch_index_path('q' => 'kitty')
    expect(page).to have_css('.result_set', count: 5)
    expect(page).to have_css('.nested_result_set', count: 5)
    # page.save_and_open_page
    within('.results_header', text: 'Catalog') do
      click_link 'View and filter all'
    end
    expect(page).to have_text 'You searched for: kitty'
  end

  # *** ARTICLES ***
  it 'should link to Articles results correctly', :js do
    visit quicksearch_index_path('q' => 'indefinite')
    expect(page).to have_css('.result_set', count: 5)
    expect(page).to have_css('.nested_result_set', count: 5)

    expect(page).to have_css('.results_header', text: 'Articles')
    within('.results_header', text: 'Articles') do
      click_link 'View and filter all'
    end
    expect(page).to have_text 'You searched for: indefinite'
  end

  # *** ACADEMIC COMMONS ***
  it 'should link to Academic Commons results correctly', :js do
    visit quicksearch_index_path('q' => 'uncommon')
    expect(page).to have_css('.result_set', count: 5)
    expect(page).to have_css('.nested_result_set', count: 5)

    # page.save_and_open_page
    within('.results_header', text: 'Academic Commons') do
      click_link 'View and filter all'
    end
    expect(page).to have_text 'You searched for: uncommon'
  end

  # *** LIBRARIES WEBSITE ***
  it 'should link to Libraries Website results correctly', :js do
    visit quicksearch_index_path('q' => 'public')
    expect(page).to have_css('.result_set', count: 5)
    expect(page).to have_css('.nested_result_set', count: 5)

    within('.result_set[data-source=lweb]') do
      expect(page).to have_css('.results_header', text: 'Libraries Website')
      expect(page).to have_css('.results_header', text: 'View all', wait: 5)
      expect(page).not_to have_css('.results_header', text: 'View and filter all')
      click_link 'View all'
    end

    # LIBSYS-3061 - Google Custom Search Widget doesn't echo back
    # search term - instead, just verify we landed on the lweb page
    # expect(page).to have_text 'You searched for: public'
    expect(page).to have_css('li.datasource_link.selected[source="lweb"]')

  end

  # NEXT-849 - Quicksearch & Other Data Sources: "i" Information Content
  # NEXT-1048 - nothing happend when you click on the little round "i"
  it 'should show  q in QuickSearch', :js do
    # QUICKSEARCH
    visit quicksearch_index_path('q' => 'horse')
    expect(page).to have_css('.nested_result_set', count: 5)

    within('.results_header[data-source=catalog]') do
      find('img').click
      expect(page).to have_css('.category_title')
      expect(find('.category_title')).to have_text 'Library books, journals, music, videos, databases, archival collections, and online resources'
    end
    within('.results_header[data-source=articles]') do
      find('img').click
      expect(page).to have_css('.category_title')
      expect(find('.category_title')).to have_text 'Articles, e-books, dissertations, music, images, and more from a mostly full-text database'
    end
    within('.results_header[data-source=ac]') do
      find('img').click
      # expect(find('.category_title')).to have_text "Publications and other research output from Columbia University's digital repository"
    end
    within('.results_header[data-source=lweb]') do
      find('img').click
      expect(page).to have_css('.category_title')
      expect(find('.category_title')).to have_text 'Information about the libraries from the Libraries Website'
    end
  end

  it 'should show popover i-button text in Dissertations', :js do
    # DISSERTATIONS
    visit dissertations_index_path('q' => 'horse')
    expect(page).to have_css('.nested_result_set', count: 3)

    within('.results_header[data-source=catalog_dissertations]') do
      find('img').click
      expect(find('.category_title')).to have_text 'Dissertations from the library catalog'
    end
    within('.results_header[data-source=articles_dissertations]') do
      find('img').click
      expect(find('.category_title')).to have_text 'Dissertations and theses from the Articles+ database. Many are full-text.'
    end
    within('.results_header[data-source=ac_dissertations]') do
      find('img').click
      expect(find('.category_title')).to have_text "Dissertations deposited in Columbia's digital repository, primarily 2011-present."
    end
  end

  it 'should show popover i-button text in E-Books', :js do
    # EBOOKS
    visit ebooks_index_path('q' => 'horse')
    expect(page).to have_css('.nested_result_set', count: 2)

    within('.results_header[data-source=catalog_ebooks]') do
      find('img').click
      expect(find('.category_title')).to have_text 'E-books from the library catalog'
    end
    within('.results_header[data-source=articles_ebooks]') do
      find('img').click
      expect(find('.category_title')).to have_text 'E-books from the Articles+ database'
    end
  end

  it 'keeps search text between queries', :js do
    visit quicksearch_index_path
    fill_in 'quicksearch_q', with: 'cats'
    click_button 'Search'

    # make sure the AJAX lookups all return
    expect(page).to have_css('.result_set', count: 5)

    # expect(page).to have_css('.result_title')

    within('.nested_result_set[data-source=catalog]') do
      expect(page).to have_css('.result_title')
      first('.result_title').find('a').click
    end
    expect(page).to have_css('#catalog_q')
    fill_in 'catalog_q', with: 'penguins'
    click_button 'Search'

    expect(page).to have_css('.result')

    first('.result').find('a').click
    expect(find('#catalog_q').value).to eq('penguins')
  end
end

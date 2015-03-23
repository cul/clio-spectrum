require 'spec_helper'

describe 'QuickSearch landing page' do

# No, it shouldn't.  The home page should show ONLY the QuickSearch search box.
  # it "should display search fields for archives, catalog, new arrivals, journals" do
  #   visit root_path
  #   page.should have_css(".search_box.catalog option")
  #   page.should have_css(".search_box.new_arrivals option")
  #   page.should have_css(".search_box.academic_commons option")
  #   page.should have_css(".search_box.journals option")
  # end

  # NEXT-612 - Quick search page doesn't let you start over
  it "should have a 'Start Over' link", js: true, Xfocus:true do
    visit quicksearch_index_path('q' => 'borneo')
    page.should have_css('.result_set', count: 4)

    # make sure all four searches have loaded their results
    expect(page).to have_css('.result_count', count: 4)

    # page.save_screenshot '/tmp/screen.png'
    all('.result_set').each do |result_set|
      # within result_set do
      #   # There should be at least one of these
      #   find('.result', match: :first)
      # end
      result_set.should have_css('.result')
    end

    find('.landing_across').should have_text('Start Over')
    within('.landing_across') do
      click_link('Start Over')
    end

    # Verify that we're now on the landing page
    page.should_not have_css('.result_set')
    page.should have_text('Quicksearch performs a combined search of')
  end

  # NEXT-1026 - Clicking 'All Results' for Libraries Website 
  # from Quicksearch shows an XML file
  # NEXT-1027 - Relabel 'All #### results' on Quicksearch
  # *** CATALOG ***
  it "should link to Catalog results correctly", js:true, Xfocus:true do
    visit quicksearch_index_path('q' => 'kitty')
    # page.save_and_open_page
    within('.results_header', :text => "Catalog") do
      click_link "View and filter all"
    end
    page.should have_text "You searched for: kitty"
  end
  # *** ARTICLES ***
  it "should link to Articles results correctly", js:true do
    visit quicksearch_index_path('q' => 'indefinite')
    within('.results_header', :text => "Articles") do
      click_link "View and filter all"
    end
    page.should have_text "You searched for: indefinite"
  end
  # *** ACADEMIC COMMONS ***
  it "should link to Academic Commons results correctly", js:true do
    visit quicksearch_index_path('q' => 'uncommon')
    # page.save_and_open_page
    within('.results_header', :text => "Academic Commons") do
      click_link "View and filter all"
    end
    page.should have_text "You searched for: uncommon"
  end
  # *** CATALOG ***
  it "should link to Libraries Website results correctly", js:true do
    visit quicksearch_index_path('q' => 'public')
    # page.save_and_open_page
    find('.results_header', :text => "Libraries Website")
    within('.results_header', :text => "Libraries Website") do
      # make sure the ajax seach has completed
      find('.result_count')
      should_not have_text "View and filter all"
      click_link "View all"
    end
    page.should have_text "You searched for: public"
  end


  # NEXT-849 - Quicksearch & Other Data Sources: "i" Information Content
  # NEXT-1048 - nothing happend when you click on the little round "i"
  it "should show popover i-button text in aggregates", js: true do
    # QUICKSEARCH
    visit quicksearch_index_path('q' => 'horse')
    within('.results_header[data-source=catalog]') do
      find('img').click
      find('.category_title').should have_text 'Library books, journals, music, videos, databases, archival collections, and online resources'
    end
    within('.results_header[data-source=articles]') do
      find('img').click
      find('.category_title').should have_text "Articles, e-books, dissertations, music, images, and more from a mostly full-text database"
    end
    within('.results_header[data-source=academic_commons]') do
      find('img').click
      find('.category_title').should have_text "Publications and other research output from Columbia University's digital repository"
    end
    within('.results_header[data-source=library_web]') do
      find('img').click
      find('.category_title').should have_text 'Information about the libraries from the Libraries Website'
    end

    # DISSERTATIONS
    visit dissertations_index_path('q' => 'horse')
    within('.results_header[data-source=catalog_dissertations]') do
      find('img').click
      find('.category_title').should have_text "Dissertations from the library catalog"
    end
    within('.results_header[data-source=dissertations]') do
      find('img').click
      find('.category_title').should have_text "Dissertations and theses from the Articles database. Many are full-text."
    end
    within('.results_header[data-source=ac_dissertations]') do
      find('img').click
      find('.category_title').should have_text "Dissertations deposited in Columbia's digital repository, primarily 2011-present."
    end

    # EBOOKS
    visit ebooks_index_path('q' => 'horse')
    within('.results_header[data-source=catalog_ebooks]') do
      find('img').click
      find('.category_title').should have_text "E-books from the library catalog"
    end
    within('.results_header[data-source=ebooks]') do
      find('img').click
      find('.category_title').should have_text "E-books from the Articles database"
    end
  end

  it "keeps search text between queries", js: true do
    visit quicksearch_index_path
    fill_in 'quicksearch_q', with: 'cats'
    click_button 'Search'
    find('.result_title', match: :first).find('a').click
    fill_in 'catalog_q', with: 'penguins'
    click_button 'Search'
    first('.result').find('a').click
    expect(find('#catalog_q').value).to eq('penguins')
  end


end

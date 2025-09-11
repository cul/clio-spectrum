require 'spec_helper'

describe 'Articles Search' do
  it 'should support range facets' do
    visit articles_index_path('q' => 'zebra')
    find('.facet_limit h5', text: 'Publication Date').click
    # Summon
    # fill_in 'pub_date_min_value',   with: 1890
    # fill_in 'pub_date_max_value',   with: 1910
    # EDS
    fill_in 'date_range_begin_year',   with: 1890
    fill_in 'date_range_end_year',   with: 1910
    click_button 'Limit'
    # save_and_open_page # debug
    find('#documents')
    expect(page.all('#documents .result').count).to be >= 10
  end

  # Articles-Summon supported advanced search.  Articles-EDS does not.
  # it 'should support multi-field searching', :js do
  xit 'should support multi-field searching', :js do
    visit root_path
    within('.landing_page') do
      click_link('Articles')
    end
    click_link('Advanced Search')

    fill_in 'query',            with: 'economics'
    fill_in 'author',           with: 'Stiglitz'
    fill_in 'title',            with: 'Economics'
    fill_in 'publicationtitle', with: 'Journal'

    click_button 'Search'
    expect(find('.well-constraints')).to have_content('Author: Stiglitz')
    expect(find('.well-constraints')).to have_content('Title: Economics')
    expect(find('.well-constraints')).to have_content('Publication Title: Journal')

    expect(page.all('#documents .result').count).to be >= 10
  end

  # NEXT-581 - Articles Advanced Search should include Publication Title search
  # NEXT-793 - add Advanced Search to Articles, support Publication Title search
  # Articles-Summon supported advanced search.  Articles-EDS does not.
  # it 'should let you perform an advanced publication title search' do
  xit 'should let you perform an advanced publication title search' do
    visit root_path
    within('li.datasource_link[source="articles"]') do
      click_link('Articles')
    end
    expect(find('#articles_q')).to be_visible

    find('.search_box.articles .advanced_search_toggle').click
    expect(find('.landing_page.articles .advanced_search')).to be_visible
    within '.landing_page.articles .advanced_search' do
      fill_in 'publicationtitle', with: 'test'

      find('button[type=submit]').click
    end

    expect(find('.well-constraints')).to have_content('Publication Title')
  end

  # NEXT-622 - Basic Articles Search should have a pull-down for fielded search
  # NEXT-842 - Articles search results page doesn't put search term back into search box
  context 'should let you perform a fielded search from the basic search' do
    before do
      visit articles_index_path
      within '.search_box.articles' do
        expect(find('#articles_q')).to be_visible
        fill_in 'q', with: 'catmull, ed'
        # find('btn.dropdown-toggle').click
        # within '.dropdown-menu' do
        #   find("a[data-value='s.fq[AuthorCombined]']").click
        # end
        select 'Author', from: 'search_field'
        find('button[type=submit]').click
      end
    end

    it 'Search string and search field should be preserved' do
      expect(find('#articles_q').value).to eq 'catmull, ed'
      expect(page).to have_select('search_field', selected: 'Author')
    end

    it 'the entered fielded search should be echoed on the results page' do
      # expect(find('.well-constraints')).to have_content('Author: catmull, ed')
      expect(find('.well-constraints')).to have_content('catmull, ed')
    end

    it 'and the search results too' do
      expect(find('#documents')).to have_content('Author Catmull')
    end

    it 'add in some test related to pub-date sorting...', :js do
      expect(first('.index_toolbar')).to have_content('Sort by Relevance')
      first(:link, 'Sort by Relevance').click

      expect(page).to have_link('Relevance')
      # expect(page).to have_link('Published Latest')
      # find_link('Published Earliest').click
      expect(page).to have_link('Date Oldest')
      find_link('Date Oldest').click

      # Summon
      # expect(first('.index_toolbar')).to have_content('Published Earliest')
      # first(:link, 'Published Earliest').click
      # expect(page).to have_link('Relevance')
      # expect(page).to have_link('Published Earliest')
      # find_link('Published Latest').click

      # EDS...
      expect(first('.index_toolbar')).to have_content('Date Oldest')
      first(:link, 'Date Oldest').click
      expect(page).to have_link('Relevance')
      expect(page).to have_link('Date Oldest')
      find_link('Date Newest').click

      expect(first('.index_toolbar')).to have_content('Date Newest')
      first(:link, 'Date Newest').click
      expect(page).to have_link('Relevance')
      expect(page).to have_link('Date Oldest')
      expect(page).to have_link('Date Newest')
    end
  end
end

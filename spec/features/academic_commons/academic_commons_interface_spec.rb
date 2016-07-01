# encoding: utf-8

require 'spec_helper'

describe 'Academic Commons', :vcr do

  it 'fielded search should work' do
    # Use this string within the below tests
    search_title_text = 'Structural and Functional Microbial Ecology'

    visit root_path

    within('li.datasource_link[source="academic_commons"]') do
      click_link('Academic Commons')
    end

    within '.search_box.academic_commons' do
      expect(find('#academic_commons_q')).to be_visible
      fill_in 'q', with: search_title_text
      # find('btn.dropdown-toggle').click
      # within '.dropdown-menu' do
      #   # save_and_open_page()
      #   click_link('Title')
      # end
      select 'Title', :from => "search_field"
      find('button[type=submit]').click
    end

    # Search string and search field should be preserved
    expect(find('#academic_commons_q').value).to eq search_title_text
    # expect(find('.btn.dropdown-toggle')).to have_content('Title')
    expect(page).to have_select('search_field', selected: 'Title')

    # The entered fielded search should be echoed on the results page
    expect(find('.constraints-container')).to have_content('Title: ' + search_title_text)

    # And the search results too
    expect(find('#documents')).to have_content(search_title_text)

    within '#documents' do
      # The example title should be a link to the item's handle
      expect(page).to have_link(search_title_text)
      href = find_link(search_title_text)[:href]
      expect(href).to match /http:\/\/hdl.handle.net\/10022\/AC:P:/

      # There should also be a Handle link to handle.net
      href = find_link('http://hdl.handle.net/10022/AC:P:')[:href]
      expect(href).to match /http:\/\/hdl.handle.net\/10022\/AC:P:/
    end

    # We can't validate remote websites without adding extra gems to our
    # testing environment.
  end

  # NEXT-1012 - use handle for item link in AC records
  it 'should link items to identifiers, not AC website', :js do
    visit quicksearch_index_path('q' => 'portuguese')

    # Make sure things load...
    expect(page).to have_css('.result_set', count: 4, wait: 10)
    expect(page).to have_css('.nested_result_set', count: 4, wait: 10)

    within('.nested_result_set[data-source=academic_commons]') do
      # We should find at least one of these...
      expect(page).to have_css('.result_title a', count: 3)
      # and each one we find must satisfy this assertion.
      all('.result_title a').each do |link|
        expect(link['href']).to satisfy { |url|
          url.match(/http:\/\/dx.doi.org\//)  || url.match(/http:\/\/hdl.handle.net\//) || url.match(/http:\/\/academiccommons.columbia.edu\//)
        }
      end
    end
  end


end




# encoding: utf-8

require 'spec_helper'

describe 'Academic Commons', focus: false do
  # Use this string within the below tests
  search_title_text = 'Structural and Functional Microbial Ecology'

  it 'fielded search should work', js: true do
    visit root_path
    within('li.datasource_link[source="academic_commons"]') do
      click_link('Academic Commons')
    end

    within '.search_box.academic_commons' do
      find('#academic_commons_q').should be_visible
      fill_in 'q', with: search_title_text
      find('btn.dropdown-toggle').click
      within '.dropdown-menu' do
        # save_and_open_page()
        click_link('Title')
      end
      find('button[type=submit]').click
    end

    # Search string and search field should be preserved
    find('#academic_commons_q').value.should eq search_title_text
    find('.btn.dropdown-toggle').should have_content('Title')

    # The entered fielded search should be echoed on the results page
    find('.constraints-container').should have_content('Title: ' + search_title_text)

    # And the search results too
    find('#documents').should have_content(search_title_text)

    within '#documents' do
      # The example title should be a link to the item's handle
      page.should have_link(search_title_text)
      href = find_link(search_title_text)[:href]
      # href.should match /http:\/\/academiccommons.columbia.edu\/catalog/
      href.should match /http:\/\/hdl.handle.net\/10022\/AC:P:/

      # There should also be a Handle link to handle.net
      href = find_link('http://hdl.handle.net/10022/AC:P:')[:href]
      href.should match /http:\/\/hdl.handle.net\/10022\/AC:P:/

    end

    # We can't validate remote websites without adding extra gems to our
    # testing environment.
  end

  # NEXT-1012 - use handle for item link in AC records
  it 'should link items to identifiers, not AC website', js: true do
    visit quicksearch_index_path('q' => 'portuguese')
    within('.nested_result_set[data-source=academic_commons]') do
      # We should find at least one of these...
      expect(page).to have_css('.result_title a')
      # and each one we find must satisfy this assertion.
      all('.result_title a').each do |link|
        link['href'].should satisfy { |url|
          url.match(/http:\/\/dx.doi.org\//)  || url.match(/http:\/\/hdl.handle.net\//)
        }
      end
    end
  end

  context 'title has link to ac item when handle is missing (NEXT-1144)', js: true do
    let(:search_results){find('.results_header[data-source=academic_commons]')}
    before do
      visit quicksearch_index_path('q' => 'Investigations into the Metabolic Requirements for Lipoic Acid')
      expect(page).to have_css('.results_header[data-source=academic_commons]')
    end
    it "search results have links to handle or ac page" do
      expect(page).to have_xpath("//div[@source=\"academic_commons\"]/div[@class=\"result_title\"]/a", count: 3)
      all(:xpath, "//div[@source=\"academic_commons\"]/div[@class=\"result_title\"]/a").each do |link|
        expect(link['href']).to match(/http:\/\/dx.doi.org\/|http:\/\/hdl.handle.net\/|http:\/\/academiccommons.columbia.edu\/catalog\/ac/)
      end
    end
  end
end




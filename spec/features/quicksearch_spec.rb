require 'spec_helper'

describe 'The home page' do

# No, it shouldn't.  The home page should show ONLY the QuickSearch search box.
  # it "should display search fields for archives, catalog, new arrivals, journals" do
  #   visit root_path
  #   page.should have_css(".search_box.catalog option")
  #   page.should have_css(".search_box.new_arrivals option")
  #   page.should have_css(".search_box.academic_commons option")
  #   page.should have_css(".search_box.journals option")
  # end

  # NEXT-612 - Quick search page doesn't let you start over
  it "should have a 'Start Over' link", js: true do
    visit quicksearch_index_path('q' => 'borneo')
    page.should have_css('.result_set', count: 4)
    all('.result_set').each do |result_set|
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

end

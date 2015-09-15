require 'spec_helper'

# Test that the correct default filter values are always applied
# when begining new searches, from any possible starting-point.
# NEXT-1079 - Articles searches from landing-page not receiving default params
describe 'Summon Search Option Filter Settings' do
  # Summon will give different total-result values upon re-querying with the same
  # parameters (server pool not in sync?).  For stable specs, pick a search term 
  # that's not that common, hoping for more search-results stability.
  # e.g., a mis-spelling, giving around 4 results.
  $q = 'whitch engish'
  @result_count = ''

  def confirm_default_filter_settings
    within('#facets') do
      within all('.facet_limit').first do
        within('.search_option', text: 'Full text online only') do
# save_and_open_screenshot
# save_and_open_page
          expect(find('input.search_option_action')).to_not be_checked
        end
        within('.search_option', text: 'Scholarly publications only') do
          expect(find('input.search_option_action')).to_not be_checked
        end
        within('.search_option', text: 'Exclude Newspaper Articles') do
          expect(find('input.search_option_action')).to be_checked
        end
        within('.search_option', text: "Columbia's collection only") do
          expect(find('input.search_option_action')).to be_checked
        end
      end
    end
  end

  it 'should default from QuickSearch panel', js: true do
    visit quicksearch_index_path('q' => $q)
    expect(page).to have_css('.result_count')

    within('.results_header[data-source=articles]') do
      expect(find('.result_count')).to have_text "View and filter all"
      @result_count = find('.result_count').text
      @result_count = @result_count.sub(/.* all (.*) results/, '\1')
      click_link "View and filter all"
    end

    expect(all('.index_toolbar.navbar').first).to have_text " of #{@result_count}"
    confirm_default_filter_settings
  end

  it 'should default from QuickSearch / DataSource link' do
    visit quicksearch_index_path('q' => $q)
    within('#datasources') do
      click_link('Articles')
    end
    expect(all('.index_toolbar.navbar').first).to have_text " of #{@result_count}"
    confirm_default_filter_settings
  end

  it 'should default from Other DataSource' do
    visit catalog_index_path('q' => $q)
    within('#datasources') do
      click_link('Articles')
    end
    expect(all('.index_toolbar.navbar').first).to have_text " of #{@result_count}"
    confirm_default_filter_settings
  end

  it 'should default from Landing Page', js: true do
    visit articles_index_path
    fill_in 'q', with: $q
    find('span.glyphicon.glyphicon-search.icon-white').click
    # page.save_and_open_page # debug
    expect(all('.index_toolbar.navbar').first).to have_text " of #{@result_count}"
    confirm_default_filter_settings
  end

  it 'should default from Start Over', js: true do
    visit articles_index_path('q' => 'albatros')
    within '.start_over' do
      find('.btn', text: 'Start Over').click
    end

    fill_in 'q', with: $q
    find('button.btn', text: Search).click
    # page.save_and_open_page # debug
    expect(all('.index_toolbar.navbar').first).to have_text " of #{@result_count}"
    confirm_default_filter_settings
  end

  # Fire off the args of the LWeb Home-Page search widget, test that
  # the defaults are correctly applied.
  # NEXT-948 Article searches from LWeb do not exclude newspapers
  it 'should default from LWeb Homepage search', js: true do
    params = { controller: 'articles', q: $q, datasource: 'articles', search_field: 'all_fields', search: true }
    visit articles_index_path(params)
    # page.save_and_open_page # debug
    expect(all('.index_toolbar.navbar').first).to have_text " of #{@result_count}"
    confirm_default_filter_settings
  end

end






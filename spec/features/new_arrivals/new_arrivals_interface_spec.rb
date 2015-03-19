require 'spec_helper'

# NEXT-845 - New Arrivals timeframe (6 month count == 1 year count)
describe 'New Arrivals Search' do

  it 'should show 4 distinct acquisition-date facet options', js: true do
    visit root_path

    within 'div#sources' do
      find_link('New Arrivals').click
    end

    find('.basic_search_button', visible: true).click

    # Find the <li> with this text, as a Capybara node...
    within1week = find('li', text: /within 1 week/i)
    # Extract from that the full-text, strip away the label to leave the count
    within1week_count =  within1week.text.gsub(/within 1 week/i, '').gsub(/\D/, '').to_i

    # And so on, for the other facet categories
    within1month = find('li', text: /within 1 month/i)
    within1month_count =  within1month.text.gsub(/within 1 month/i, '').gsub(/\D/, '').to_i

    within6months = find('li', text: /within 6 months/i)
    within6months_count =  within6months.text.gsub(/within 6 months/i, '').gsub(/\D/, '').to_i

    within1year = find('li', text: /within 1 year/i)
    within1year_count =  within1year.text.gsub(/within 1 year/i, '').gsub(/\D/, '').to_i

    # Now, assert some basic sanity checks on sizes and relationships

    within1week_count.should be > 100
    within1month_count.should be > 1000
    within6months_count.should be > 10_000
    within1year_count.should be > 100_000

    within1month_count.should be > within1week_count
    within6months_count.should be > within1month_count
    within1year_count.should be > within6months_count

  end

  it 'will be able to traverse next and previous links' do
    visit new_arrivals_index_path('q' => 'd*o*g*')

    page.should_not have_css('.index_toolbar a', text: 'Previous')
    page.should have_css('.index_toolbar a', text: 'Next')

    all('.index_toolbar a', text: 'Next').first.click

    page.should have_css('.index_toolbar a', text: 'Previous')
    page.should have_css('.index_toolbar a', text: 'Next')

    all('.index_toolbar a', text: 'Previous').first.click

    page.should_not have_css('.index_toolbar a', text: 'Previous')
    page.should have_css('.index_toolbar a', text: 'Next')
  end

  it 'can move between item-detail and search-results', js: true do
    visit new_arrivals_index_path('q' => 'man')

    within all('.result.document').first do
      all('a').first.click
    end

    # page.save_and_open_page # debug

    # find('#search_info').should have_text '1 of '
    find('#search_info', text: '1 of ')
    page.should_not have_css('#search_info a', text: 'Previous')
    page.should have_css('#search_info a', text: 'Next')

    find('#search_info a', text: 'Next').click

    # find('#search_info').should have_text '2 of '
    find('#search_info', text: '2 of ')
    page.should have_css('#search_info a', text: 'Previous')
    page.should have_css('#search_info a', text: 'Next')

    find('#search_info a', text: 'Previous').click

    # find('#search_info').should have_text '1 of '
    find('#search_info', text: '1 of ')
    page.should_not have_css('#search_info a', text: 'Previous')
    page.should have_css('#search_info a', text: 'Next')

    find('#search_info a', text: 'Back to Results').click

    find('.constraints-container').should have_text 'You searched for: man'

  end

end

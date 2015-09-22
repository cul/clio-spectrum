require 'spec_helper'

# NEXT-845 - New Arrivals timeframe (6 month count == 1 year count)
describe 'New Arrivals Search', :vcr do

  it 'should show 4 distinct acquisition-date facet options', :js do
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

    expect(within1week_count).to be > 100
    expect(within1month_count).to be > 1000
    expect(within6months_count).to be > 10_000
    expect(within1year_count).to be > 100_000

    expect(within1month_count).to be > within1week_count
    expect(within6months_count).to be > within1month_count
    expect(within1year_count).to be > within6months_count

  end

  it 'will be able to traverse next and previous links' do
    visit new_arrivals_index_path('q' => 'd*o*g*')

    expect(page).to_not have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')

    all('.index_toolbar a', text: 'Next').first.click

    expect(page).to have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')

    all('.index_toolbar a', text: 'Previous').first.click

    expect(page).to_not have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')
  end

  it 'can move between item-detail and search-results', :js do
    visit new_arrivals_index_path('q' => 'man')

    within all('.result.document').first do
      all('a').first.click
    end

    # page.save_and_open_page # debug

    expect(find('#search_info')).to have_text '1 of '
    expect(page).to_not have_css('#search_info a', text: 'Previous')
    expect(page).to have_css('#search_info a', text: 'Next')

    find('#search_info a', text: 'Next').click

    expect(find('#search_info')).to have_text '2 of '
    expect(page).to have_css('#search_info a', text: 'Previous')
    expect(page).to have_css('#search_info a', text: 'Next')

    find('#search_info a', text: 'Previous').click

    expect(find('#search_info')).to have_text '1 of '
    expect(page).to_not have_css('#search_info a', text: 'Previous')
    expect(page).to have_css('#search_info a', text: 'Next')

    find('#search_info a', text: 'Back to Results').click

    expect(find('.constraints-container')).to have_text 'You searched for: man'

  end

end

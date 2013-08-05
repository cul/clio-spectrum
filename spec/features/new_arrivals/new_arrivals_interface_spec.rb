require 'spec_helper'

# NEXT-845 - New Arrivals timeframe (6 month count == 1 year count)
describe "New Arrivals Search" do

  it "should show 4 distinct acquisition-date facet options", :js => true do
    visit root_path

    within 'div#sources' do
      find_link("New Arrivals").click
    end

    find('.basic_search_button', :visible => true).click

    # Find the <li> with this text, as a Capybara node...
    within1week = find('li', :text => /within 1 week/i)
    # Extract from that the full-text, strip away the label to leave the count
    within1week_count =  within1week.text.gsub(/within 1 week/i, '').gsub(/\D/,'').to_i

    # And so on, for the other facet categories
    within1month = find('li', :text => /within 1 month/i)
    within1month_count =  within1month.text.gsub(/within 1 month/i, '').gsub(/\D/,'').to_i

    within6months = find('li', :text => /within 6 months/i)
    within6months_count =  within6months.text.gsub(/within 6 months/i, '').gsub(/\D/,'').to_i

    within1year = find('li', :text => /within 1 year/i)
    within1year_count =  within1year.text.gsub(/within 1 year/i, '').gsub(/\D/,'').to_i

    # Now, assert some basic sanity checks on sizes and relationships

    within1week_count.should be > 100
    within1month_count.should be > 1000
    within6months_count.should be > 10000
    within1year_count.should be > 100000

    within1month_count.should be > within1week_count
    within6months_count.should be > within1month_count
    within1year_count.should be > within6months_count

  end

end


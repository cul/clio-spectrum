require 'spec_helper'

describe 'An articles search' do

  it 'will have a next link that links to articles' do
    visit articles_index_path('q' => 'test')
    expect(page).to have_css('.index_toolbar a', text: 'Next')
    el = all('.index_toolbar a', text: 'Next').first
    el['href'].should include('/articles')
  end

  it 'will be able to traverse next and previous links' do
    visit articles_index_path('q' => 'test')

    expect(page).to_not have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')
# save_and_open_page

    all('.index_toolbar a', text: 'Next').first.click
# save_and_open_page
    expect(page).to have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')

    all('.index_toolbar a', text: 'Previous').first.click

    expect(page).to_not have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')
  end


  # NEXT-1078 - CLIO Articles limit 500 records, Summon 1,000
  it 'can paginate through 1000 total items' do
    visit articles_index_path('q' => 'Aardvark', 's.pn' => 20, 's.ps' => 50)
    expect(page).to have_text('Aardvark')
    expect(page).to have_text('« Previous | 951 - 1000 of ')
    expect(page).to_not have_text('There was an error searching this datasource')

    visit articles_index_path('q' => 'Aardvark', 's.pn' => 21, 's.ps' => 50)
    expect(page).to have_text('There was an error searching this datasource. (Maximum supported returned results set size is 1000 (provided size is 1050).)')

    visit articles_index_path('q' => 'Aardvark', 's.pn' => 20, 's.ps' => 51)
    expect(page).to have_text('There was an error searching this datasource. (Maximum supported page size is 50 (provided size is 51).)')

  end

end


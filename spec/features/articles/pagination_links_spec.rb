require 'spec_helper'

describe 'An articles search' do
  it 'will have a next link that links to articles' do
    visit articles_index_path('q' => 'test')
    expect(page).to have_css('.index_toolbar a', text: 'Next')
    el = all('.index_toolbar a', text: 'Next').first
    expect(el['href']).to have_text '/articles'
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

  # NEXT-1078 - CLIO Articles limit 500 records, Summon 1,000, EDS apparently no limit!
  it 'can paginate through 1000 total items' do
    visit articles_index_path('q' => 'Aardvark', 'pagenumber' => 20, 'results_per_page' => 50)
    expect(page).to have_text('Aardvark')
    expect(page).to have_text('« Previous | 951 - 1000 of ')
  end
end

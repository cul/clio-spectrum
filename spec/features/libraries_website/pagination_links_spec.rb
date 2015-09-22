require 'spec_helper'

describe 'A Libraries Website search', :vcr do

  it 'will have a next link that links to library_web' do
    visit library_web_index_path('q' => 'books')
    expect(page).to have_css('.index_toolbar a', text: 'Next')
    el = all('.index_toolbar a', text: 'Next').first
    expect(el['href']).to have_text '/library_web'
  end

  it 'will be able to traverse next and previous links' do
    visit library_web_index_path('q' => 'books')

    expect(page).to_not have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')

    all('.index_toolbar a', text: 'Next').first.click

    expect(page).to have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')

    all('.index_toolbar a', text: 'Previous').first.click

    expect(page).to_not have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')
  end
end

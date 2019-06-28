require 'spec_helper'

describe 'A Libraries Website search' do
  it 'will have a next link that links to lweb' do
    visit lweb_index_path('q' => 'books')
    expect(page).to have_css('.index_toolbar a', text: 'Next')
    el = all('.index_toolbar a', text: 'Next').first
    # expect(el['href']).to have_text '/library_web'
    expect(el['href']).to have_text '/lweb'
  end

  it 'will be able to traverse next and previous links' do
    visit lweb_index_path('q' => 'books')

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

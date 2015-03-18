require 'spec_helper'

describe 'E-Journals Search' do

  it 'will be able to traverse next and previous links' do
    visit journals_index_path('q' => 'notes')

    expect(page).to_not have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')

    all('.index_toolbar a', text: 'Next').first.click

    expect(page).to have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')

    all('.index_toolbar a', text: 'Previous').first.click

    expect(page).to_not have_css('.index_toolbar a', text: 'Previous')
    expect(page).to have_css('.index_toolbar a', text: 'Next')
  end

  it 'can move between item-detail and search-results', js: true do
    visit journals_index_path('q' => 'letters')

    within all('.result.document').first do
      all('a').first.click
    end

    # page.save_and_open_page # debug

    find('#search_info').should have_text '1 of '
    expect(page).to_not have_css('#search_info a', text: 'Previous')
    expect(page).to have_css('#search_info a', text: 'Next')

    find('#search_info a', text: 'Next').click

    find('#search_info').should have_text '2 of '
    expect(page).to have_css('#search_info a', text: 'Previous')
    expect(page).to have_css('#search_info a', text: 'Next')

    find('#search_info a', text: 'Previous').click

    find('#search_info').should have_text '1 of '
    expect(page).to_not have_css('#search_info a', text: 'Previous')
    expect(page).to have_css('#search_info a', text: 'Next')

    find('#search_info a', text: 'Back to Results').click

    find('.constraints-container').should have_text 'You searched for: letters'

  end

end

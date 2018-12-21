require 'spec_helper'

describe 'Database Highlights', :vcr do
  it 'Should show highlighting in QuickSearch', :js do
    visit quicksearch_index_path('q' => 'medline ipswich')
    expect(page).to have_css('.result_set', count: 5)
    expect(page).to have_css('.nested_result_set', count: 5)
    within('.nested_result_set[data-source=catalog]') do
      find('.result.database_record', text: 'MEDLINE')
    end
  end

  it 'Should show highlighting in Catalog search' do
    visit catalog_index_path('q' => 'medline ipswich')
    within('#documents') do
      find('.result.database_record', text: 'MEDLINE')
    end
  end

  it 'Should show highlighting in Databases search' do
    visit databases_index_path('q' => 'medline ipswich')
    within('#documents') do
      find('.result.database_record', text: 'MEDLINE')
    end
  end

  it 'Should show highlighting in Virtual Shelf Browse', :js do
    # This item's call-number is just before that of "MEDLINE"
    visit solr_document_path(7928198)
    find('.btn.show_mini_browse', text: 'Show').click

    expect(page).to have_css('#nearby .nearby_content')
    expect(page).to have_css('#documents')
    within('#documents') do
      find('.result.database_record', text: 'MEDLINE')
    end
  end
end

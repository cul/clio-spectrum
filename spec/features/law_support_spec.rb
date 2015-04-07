require 'spec_helper'

describe 'CLIO support for Law records' do

  it 'should include Law in Location facet', js: true do
    visit catalog_index_path('q' => 'supr* cour*')
    within '.facets.sidenav' do
      find('h5', text: 'Location').click
    end
    within all('.blacklight-location_facet').first do
      click_link 'Law'
    end
    expect(page).to have_css('.result.document')
    all('.result.document').each do |result_document|
      result_document.should have_text 'Law'
      result_document.should have_link('Check Law catalog for status')
    end

    # Now dismiss "supr* cour*", to get full listing of all law records...
    within find('.constraint-box', text: 'supr') do
      find('.glyphicon.glyphicon-remove').click
    end

    # confirm
    expect(find('.blacklight-location_facet .facet-content')).to have_css('li', maximum: 1)
    expect(find('.blacklight-location_facet .facet-content')).to have_text('Law')

    # Now, inverse "Law" to "Not Law"
    within find('.constraint-box', text: 'Location') do
      find('.dropdown', text: 'Is').click
      find('a', text: 'Is Not').click
    end

    # confirm
    expect(find('.blacklight-location_facet .facet-content')).to have_css('li', minimum: 5)
    expect(find('.blacklight-location_facet .facet-content')).to have_text 'NOT Law'

    # go back, should get to Law again
    page.evaluate_script('window.history.back()')

    # confirm
    expect(find('.blacklight-location_facet .facet-content')).to have_css('li', maximum: 1)
    expect(find('.blacklight-location_facet .facet-content')).to have_text('Law')

  end

  it 'should link to precise bib for known item' do
    visit catalog_index_path('q' => 'supr* cour* felix aime')
    expect(find('.result.document')).to have_text 'Law Trials C5453'
    expect(find('.result.document')).to have_link('Check Law catalog for status', href: 'http://pegasus.law.columbia.edu/record=b402660')

  end

end

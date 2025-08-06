require 'spec_helper'

describe 'collection output tests' do
  it 'test condensed holdings output full', :js, wait: 20 do
    visit solr_document_path('8430339')
    within ('div#clio_holdings') do
      # page.save_and_open_page # debug
      expect(page).to have_text('Butler Stacks')
    end

    visit solr_document_path('1052500')
    expect(page).to have_css('#clio_holdings .holding')
    within ('div#clio_holdings') do
      expect(page).to have_text('MICROFLM FN 41 Library has: v.1851:Sept.-2003:Dec.14, 2004:Jan.')
    end
  end

  it 'test condensed holdings output brief', :js do
    visit solr_document_path('2033')
    within ('div#clio_holdings') do
      expect(page).to have_text('Butler Stacks')
      expect(page).to have_text('PQ6046.B5 S25')
      
      # COVID OVERRIDE SPEC
      expect(page).not_to have_text('Scan & Deliver')
      # restore the following:
      # # expect(page).to have_text('Scan & Deliver')
    end
  end
end

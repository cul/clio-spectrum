require 'spec_helper'

describe 'collection output tests', vcr: { allow_playback_repeats: true } do

  it 'test condensed holdings output full', :js, wait: 20 do

    visit catalog_path('8430339')
    within ('div#clio_holdings') do
      expect(page).to have_text('Butler Stacks (Enter at the Butler Circulation Desk)')
    end

    visit catalog_path('1052500')
    within ('div#clio_holdings') do
      expect(page).to have_text('MICROFLM FN 41 Library has: v.1851:Sept.-2003:Dec.14, 2004:Jan.')
    end

  end

  it 'test condensed holdings output brief', :js do

    visit catalog_path('8430339')
    within ('div#clio_holdings') do
      expect(page).to have_text('Butler Stacks (Enter at the Butler Circulation Desk)')
      expect(page).to have_text('BL80.3 .D74 2011')
      expect(page).to have_text('Scan & Deliver')
    end

  end
end

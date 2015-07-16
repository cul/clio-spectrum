require 'spec_helper'

describe 'record tests', js: true do

  it 'test adjust services' do

    # Butler suppress doc delivery
    visit catalog_path('9702637')
    within ('div#clio_holdings') do
      expect(page).to_not have_text('Scan & Deliver')
    end

    # suppress bd and ill, copy available
    visit catalog_path('9420109')
    within ('div#clio_holdings') do
      expect(page).to_not have_text('Borrow Direct')
      expect(page).to_not have_text('ILL')
    end

  end

end

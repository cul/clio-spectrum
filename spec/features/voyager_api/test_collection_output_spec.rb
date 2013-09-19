require 'spec_helper'

describe "collection output tests", :js => true do

  it "test condensed holdings output full" do

    visit catalog_path('8430339')
    within ('div#clio_holdings') do
      page.should have_text('Butler Stacks (Enter at the Butler Circulation Desk)')
    end

    visit catalog_path('1052500')
    within ('div#clio_holdings') do
      page.should have_text('MICROFLM FN 41 Library has: v.1851:Sept.-2003:Dec.14, 2004:Jan.-2013:July 31')
    end

  end

  it "test condensed holdings output brief" do

    visit catalog_path('8430339')
    within ('div#clio_holdings') do
      page.should have_text('Butler Stacks (Enter at the Butler Circulation Desk)')
      page.should have_text('BL80.3 .D74 2011')
      page.should have_text('Scan & Deliver')
    end


  end
end


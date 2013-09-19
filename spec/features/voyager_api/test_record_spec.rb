require 'spec_helper'

describe "record tests", :js => true do

  it "test call number" do
    visit catalog_path('7686002')
    within ('div#clio_holdings') do
      page.should have_text('Ms MONTGOM 675')
    end
  end

  it "test supplements" do
    visit catalog_path('2120018')
    within ('div#clio_holdings') do
      page.should have_text('1880-1881 bound in 1 v.')
    end
  end

  it "test online record" do
    visit catalog_path('5656993')
    within ('div.location_box') do
      page.should have_text('Online')
    end
    within ('div#clio_holdings') do
      page.should_not have_text('Online')
    end
  end

  it "test services offsite" do
    visit catalog_path('6249927')
    within ('div#clio_holdings') do
      page.should have_link('Offsite',
        :href => 'http://www.columbia.edu/cgi-bin/cul/offsite2?6249927' )
    end
  end

  it "test donor info" do
    visit catalog_path('5602687')
    within ('div#clio_holdings') do
      page.should have_text('Donor: Gift; Paul Levitz; 2012.')
    end
  end

  it "test service spec coll" do
    visit catalog_path('10104738')
    within ('div#clio_holdings') do
      page.should have_link('Special Collections',
        :href => 'http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey=10104738' )
    end
  end

  it "test service spec coll" do
    visit catalog_path('6201975')
    within ('div#clio_holdings') do
      page.should have_link('Scan & Deliver',
        :href => 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?6201975',
        :count => 3 )
    end

    visit catalog_path('6871895')
    within ('div#clio_holdings') do
      page.should have_link('Scan & Deliver',
        :href => 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?6871895',
        :count => 2 )
    end

  end

end




7686002
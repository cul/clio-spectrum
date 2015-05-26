require 'spec_helper'

describe 'record tests', js: true do

  it 'test call number' do
    visit catalog_path('7686002')
    within ('div#clio_holdings') do
      expect(page).to have_text('Ms MONTGOM 675')
    end
  end

  it 'test supplements' do
    visit catalog_path('2120018')
    within ('div#clio_holdings') do
      expect(page).to have_text('1880-1881 bound in 1 v.')
    end
  end

  it 'test online record' do
    visit catalog_path('5656993')
    within ('div.location_box') do
      expect(page).to have_text('Online')
    end
    # Online only, no clio-holdings div at all!
    # within ('div#clio_holdings') do
    #   expect(page).to_not have_text('Online')
    # end
    expect(page).to have_no_selector('div#clio_holdings')
  end

  it 'test services offsite' do
    visit catalog_path('6249927')
    within ('div#clio_holdings') do
      expect(page).to have_link('Offsite',
                            href: 'http://www.columbia.edu/cgi-bin/cul/offsite2?6249927')
    end
  end

  context 'donor info' do

    it 'test donor info' do
      visit catalog_path('5602687')
      within ('div#clio_holdings') do
        expect(page).not_to have_content('Donor:')
        expect(page).to have_content('Paul Levitz; 2012.')
        expect(page).to have_css('.donor_info_icon')
      end
    end

    it 'test donor info icon' do
      visit catalog_path('9576776')
      within ('div#clio_holdings') do
        expect(page).not_to have_content('Donor:')
        expect(page).to have_content('John Morrow; 2013')
        expect(page).to have_css('.donor_info_icon')
      end
    end

    # NEXT-1180 - Accommodate donor info that spans one or two lines
    it 'test donor info with very, very, very, very, very, very long donor label' do
      visit catalog_path('36114')
      within ('div#clio_holdings') do
        expect(page).not_to have_content('Donor:')
        # expect(page).to have_content('Seymour Durst; 2012.')
        ridicule = 'Seymour B. Durst Old York Library Collection, Avery Architectural & Fine Arts Library, Columbia University.'
        expect(page).to have_content(ridicule)
        expect(page).to have_css('.donor_info_icon')
      end
    end
  end

  it 'test service spec coll' do
    visit catalog_path('10104738')
    within ('div#clio_holdings') do
      expect(page).to have_link('Special Collections',
                            href: 'http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey=10104738')
    end
  end

  it 'test service spec coll' do
    visit catalog_path('6201975')
    within ('div#clio_holdings') do
      expect(page).to have_link('Scan & Deliver',
                            href: 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?6201975')
    end

    visit catalog_path('6871895')
    within ('div#clio_holdings') do
      expect(page).to have_link('Scan & Deliver',
                            href: 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?6871895',
                            count: 2)
    end

  end

end

7_686_002

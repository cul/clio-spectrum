require 'spec_helper'

describe 'record tests' do
  it 'test call number', :js do
    visit solr_document_path('7686002')

    # page.save_and_open_page
    # page.save_and_open_screenshot

    expect(page).to have_css('#clio_holdings .holding')
    within ('div#clio_holdings') do
      expect(page).to have_text('Ms MONTGOM 675')
    end
  end

  it 'test supplements', :js do
    visit solr_document_path('2120018')
    expect(page).to have_css('#clio_holdings .holding')
    within ('div#clio_holdings') do
      expect(page).to have_text('1880-1881 bound in 1 v.')
    end
  end

  it 'test online record' do
    visit solr_document_path('5656993')
    within ('div.location_box') do
      expect(page).to have_text('Online')
    end
    within ('div#clio_holdings') do
      expect(page).to_not have_text('Online')
    end
  end

  it 'test services offsite', :js do
    visit solr_document_path('6249927')
    expect(page).to have_css('#clio_holdings .holding', wait: 20)
    within ('div#clio_holdings') do
      # # COVID OVERRIDE SPEC - link logic flipped, link label changed
      # expect(page).not_to have_link('Offsite')
      # # restore the following:
      expect(page).to have_link('Scan')

      # The href is blank - the Valet URL is in the onclick JS code
      # href: 'https://valet.cul.columbia.edu/offsite_requests/bib?bib_id=6249927')
    end
  end

  context 'donor info' do
    it 'test donor info', :js do
      visit solr_document_path('5602687')
      expect(page).to have_css('#clio_holdings .holding')
      within ('div#clio_holdings') do
        expect(page).not_to have_content('Donor:')
        expect(page).to have_content('Paul Levitz; 2012.')
        expect(page).to have_css('.donor_info_icon')
      end
    end

    it 'test donor info icon', :js do
      visit solr_document_path('9576776')
      expect(page).to have_css('#clio_holdings .holding')
      within ('div#clio_holdings') do
        expect(page).not_to have_content('Donor:')
        expect(page).to have_content('John Morrow; 2013')
        expect(page).to have_css('.donor_info_icon')
      end
    end

    # NEXT-1180 - Accommodate donor info that spans one or two lines
    it 'test donor info with very, very, very, very, very, very long donor label', :js do
      visit solr_document_path('36114')
      expect(page).to have_css('#clio_holdings .holding', wait: 20)
      within ('div#clio_holdings') do
        expect(page).not_to have_content('Donor:')
        # expect(page).to have_content('Seymour Durst; 2012.')
        ridicule = 'Seymour B. Durst Old York Library Collection, Avery Architectural & Fine Arts Library, Columbia University.'
        expect(page).to have_content(ridicule)
        expect(page).to have_css('.donor_info_icon')
      end
    end
  end

  it 'special collections link', :js do
    visit solr_document_path('10104738')
    expect(page).to have_css('#clio_holdings .holding')
    within ('div#clio_holdings') do
      expect(page).to have_link('Special Collections', href: 'http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey=10104738')
    end
  end

  it 'special collections link for uacl,low', :js do
    visit solr_document_path('12954047')
    expect(page).to have_css('#clio_holdings .holding')
    within ('div#clio_holdings') do
      expect(page).to have_link('Special Collections', href: 'http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey=12954047')
    end
  end

  # LIBSYS-4156 - disable microform service
  # # NEXT-1706 - PMRR special handling
  # it 'microform link', :js do
  #   visit solr_document_path('3124506')
  #   expect(page).to have_css('#clio_holdings .holding')
  #   within ('div#clio_holdings') do
  #     expect(page).to have_link('Arrange for Access', href: 'https://library.columbia.edu/libraries/pmrr/services.html?3124506')
  #   end
  # end

  it 'special collections services', :js do
    visit solr_document_path('6201975')
    expect(page).to have_css('#clio_holdings .holding')
    within ('div#clio_holdings') do
      # COVID OVERRIDE SPEC
      expect(page).not_to have_link('Scan & Deliver', href: 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?6201975')
      # restore the following:
      # # expect(page).to have_link('Scan & Deliver', href: 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?6201975')
    end

    # visit solr_document_path('6871895')
    # expect(page).to have_css('#clio_holdings .holding')
    # within ('div#clio_holdings') do
    #   expect(page).to have_link('Scan & Deliver',
    #                         href: 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?6871895',
    #                         count: 3)
    # end
  end
end

7_686_002

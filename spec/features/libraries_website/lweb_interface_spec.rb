require 'spec_helper'

describe 'Libraries Website DAM search', :vcr do
  it 'should show DAM filenames and format icons for XLS' do
    visit lweb_index_path('q' => 'dam sheet1 xlsx')
    within all('.result.document').first do
      expect(find('img')['src']).to have_content 'xlsx.png'
      expect(find('.lweb_dam_document')).to have_text '.xlsx'
    end
  end

  it 'should show DAM filenames and format icons for DOC' do
    visit lweb_index_path('q' => 'hints on researching doc dam')
    within all('.result.document').first do
      expect(find('img')['src']).to have_content 'doc.png'
      expect(find('.lweb_dam_document')).to have_text '.doc'
    end
  end

  it 'should show DAM filenames and format icons for PDF' do
    visit lweb_index_path('q' => 'dam pdf guide')
    within all('.result.document').first do
      expect(find('img')['src']).to have_content 'pdf.png'
      expect(find('.lweb_dam_document')).to have_text '.pdf'
    end
  end
end

describe 'Libraries Website searches', :vcr do
  # 3/2019 - NEXT-1570 - Cutover to Google Custom Search
  # Google Custom Search only allows max 10 page of 10 results,
  # so this test is not really meaningful anymore.
  it 'should remember items-per-page' do
    # SET initial page-size to 10 items
    visit lweb_index_path('q' => 'room')
    within all('.index_toolbar.navbar').first do
      find('.dropdown-toggle', text: 'Display Options').click
      click_link 'Display Options'
      click_link '10 per page'
    end

    # Confirm 10-items returned upon next search
    visit lweb_index_path('q' => 'book')
    within all('.index_toolbar.navbar').first do
      expect(find('#current_item_info')).to have_text '1 - 10 of'
    end

    # SET page-size to same value, 10 items
    within all('.index_toolbar.navbar').first do
      find('.dropdown-toggle', text: 'Display Options').click
      click_link 'Display Options'
      click_link '10 per page'
    end

    # Confirm 10-items returned upon next search
    visit lweb_index_path('q' => 'library')
    within all('.index_toolbar.navbar').first do
      expect(find('#current_item_info')).to have_text '1 - 10 of'
    end
  end
end

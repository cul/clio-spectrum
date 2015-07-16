require 'spec_helper'

describe 'Libraries Website DAM search' do

  it 'should show DAM filenames and format icons for XLS' do
    visit library_web_index_path('q' => 'dam sheet1 xlsx')
    within all('.result.document').first do
      expect(find('img')['src']).to have_content 'xlsx.png'
      expect(find('.lweb_dam_document')).to have_text '.xlsx'
    end
  end

  it 'should show DAM filenames and format icons for DOC' do
    visit library_web_index_path('q' => 'reproduction form doc dam')
    within all('.result.document').first do
      expect(find('img')['src']).to have_content 'doc.png'
      expect(find('.lweb_dam_document')).to have_text '.doc'
    end
  end

  it 'should show DAM filenames and format icons for PDF' do
    visit library_web_index_path('q' => 'dam pdf guide')
    within all('.result.document').first do
      expect(find('img')['src']).to have_content 'pdf.png'
      expect(find('.lweb_dam_document')).to have_text '.pdf'
    end
  end

end

describe 'Libraries Website searches' do

  it 'should remember items-per-page' do

    # SET initial page-size to 100 items
    visit library_web_index_path('q' => 'room')
    within all('.index_toolbar.navbar').first do
      find('.dropdown-toggle', text: 'Display Options').click
      click_link 'Display Options'
      click_link '100 per page'
    end

    # Confirm 100-items returned upon next search
    visit library_web_index_path('q' => 'book')
    within all('.index_toolbar.navbar').first do
      expect(find('#current_item_info')).to have_text '1 - 100 of'
    end

    # SET page-size to new value, 25 items
    within all('.index_toolbar.navbar').first do
      find('.dropdown-toggle', text: 'Display Options').click
      click_link 'Display Options'
      click_link '25 per page'
    end

    # Confirm 25-items returned upon next search
    visit library_web_index_path('q' => 'library')
    within all('.index_toolbar.navbar').first do
      expect(find('#current_item_info')).to have_text '1 - 25 of'
    end

  end

end

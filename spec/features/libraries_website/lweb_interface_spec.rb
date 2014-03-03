require 'spec_helper'

describe "CLIO LWeb interface" do

  it "should show DAM filenames and format icons for XLS" do
    visit library_web_index_path('q' => 'dam sheet1 xlsx')
    within all('.result.document').first do
      find('img')['src'].should have_content 'xlsx.png'
      find('.lweb_dam_document').should have_text '.xlsx'
    end
  end

  it "should show DAM filenames and format icons for DOC" do
    visit library_web_index_path('q' => 'dam doc form')
    within all('.result.document').first do
      find('img')['src'].should have_content 'doc.png'
      find('.lweb_dam_document').should have_text '.doc'
    end
  end

  it "should show DAM filenames and format icons for PDF" do
    visit library_web_index_path('q' => 'dam pdf guide')
    within all('.result.document').first do
      find('img')['src'].should have_content 'pdf.png'
      find('.lweb_dam_document').should have_text '.pdf'
    end
  end

end


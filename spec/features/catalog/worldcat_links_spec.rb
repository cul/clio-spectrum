require 'spec_helper'

describe 'WorldCat links' do

  it 'should link for simple OCLC numbers' do
    # A very sparse catalog record
    visit solr_document_path('123')
    within '.holdings' do
      expect(page).to have_link('WorldCat', href: 'https://worldcat.org/search?q=no:3777209')
    end

    # A document with Hathi links - WorldCat shouls still show up the same
    visit solr_document_path('513297')
    within '.holdings' do
      expect(page).to have_link('WorldCat', href: 'https://worldcat.org/search?q=no:2218446')
    end
  end

  it 'should link for prefixed OCLC numbers' do
    visit solr_document_path('12605255')
    within '.holdings' do
      expect(page).to have_link('WorldCat', href: 'https://worldcat.org/search?q=no:133167834')
    end
  end

  it 'should not link when standard numbers absent' do
    # A catalog record with no OCLC number at all
    visit solr_document_path('11765916')
    within '.holdings' do
      expect(page).not_to have_link('WorldCat')
    end
  end

end

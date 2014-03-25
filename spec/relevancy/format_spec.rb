# -*- encoding : utf-8 -*-
require 'spec_helper'

# Fix up Computer Program, Computer File, etc.
# NEXT-970 - Some bibs assigned format "Computer File" instead of "Other"
describe 'Format assignments for types of "Computer Files"' do

  it 'Double format:  Computer File and Online' do
    bibList = [2_972_693, 3_105_451, 3_120_827]
    bibList.each do |bib|
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      # Assert the precise list of formats
      formatList.should == ['Computer File', 'Online']
      # Assert the presence of each format
      # resp.should include("format" => 'Computer File')
      # resp.should include("format" => 'Online')
    end

  end

  it 'Single format:  Other' do
    bibList = [8_617_143]
    bibList.each do |bib|
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      formatList.should == ['Other']
    end
  end

  it 'Single format:  Computer File' do
    bibList = [2_996_414, 3_041_516, 3_238_417, 3_359_137]
    bibList.each do |bib|
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      formatList.should == ['Computer File']
    end
  end

  it 'Single format:  Computer Program' do
    bibList = [519_699, 519_712, 620_786, 705_052, 742_254, 959_054, 1_242_420]
    bibList.each do |bib|
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      formatList.should == ['Computer Program']
    end
  end

end

# NEXT-975 - Serial records coded as "monographic series."
# Monographic Series should be treated as 'Journal/Periodical', and not Book.
describe 'Format assignments for Monographic Series' do
  it 'Should have format Journal/Periodical' do
    bibList = [130_062, 774_424, 2_237_522, 3_948_829]
    bibList.each do |bib|
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      formatList.should == ['Journal/Periodical']
    end
  end
end

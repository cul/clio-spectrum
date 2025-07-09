# -*- encoding : utf-8 -*-
require 'spec_helper'

# Fix up Computer Program, Computer File, etc.
# NEXT-970 - Some bibs assigned format "Computer File" instead of "Other"
describe 'Format assignments for types of "Computer Files"', :skip_travis do
  bibList = [2972693, 3105451]
  bibList.each do |bib|
    it "bib #{bib} should have single format: 'Online'" do
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      # Assert the precise list of formats
      expect(formatList).to be == ['Online']
    end
  end

  bibList = [2525964]
  bibList.each do |bib|
    it "bib #{bib} should have two formats: 'Computer File' && US Gov.Doc." do
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      expect(formatList).to be == ['Computer File', 'US Government Document']
    end
  end

  bibList = [3041516, 3238417]
  bibList.each do |bib|
    it "bib #{bib} should have single format: 'Computer File'" do
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      expect(formatList).to be == ['Computer File']
    end
  end

  bibList = [519699, 519712, 620786, 705052, 742254, 959054, 1242420]
  bibList.each do |bib|
    it "bib #{bib} should have single format: 'Computer Program'" do
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      expect(formatList).to be == ['Computer Program']
    end
  end
end

# NEXT-975 - Serial records coded as "monographic series."
# Monographic Series should be treated as 'Journal/Periodical', and not Book.
describe 'Format assignments for Monographic Series', :skip_travis do
  bibList = [774424, 2237522, 3948829]
  bibList.each do |bib|
    it "bib #{bib} should have format 'Journal/Periodical'" do
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      expect(formatList).to be == ['Journal/Periodical']
    end
  end
end

# NEXT-1141 - Improve Format Assignment
describe 'Updated Format Assignments', :skip_travis do
  {
    8761270 => 'Book',
    8761542 => 'Book',
    8877512 => 'Book',

    10787097 => 'Computer File',
    10657222 => 'Computer File',
    10291684 => 'Computer File',

    8600916 => 'Manuscript/Archive',
    8601514 => 'Manuscript/Archive',
    8601851 => 'Manuscript/Archive',

    8224087 => 'Image',
    8224088 => 'Image',
    8224090 => 'Image',

    8225257 => 'Journal/Periodical',
    1033597 => 'Journal/Periodical',
    5321235 => 'Journal/Periodical',

    11138471 => ['Journal/Periodical', 'Loose-leaf'],
    11149683 => ['Journal/Periodical', 'Loose-leaf'],
    # 'law173555' => ['Journal/Periodical', 'Loose-leaf'],
    # 'law192394' => ['Journal/Periodical', 'Loose-leaf'],

    3740193 => %w(Book Microformat),
    10819290 => %w(Book Microformat),
    # 'law290915' => %w(Book Microformat),
    # 'law175050' => %w(Book Microformat)
  }.each do |bib, formatValue|

    it "assigns '#{formatValue}' to #{bib}" do
      resp = solr_response('q' => "id:#{bib}", 'fl' => 'id,format', 'facet' => false)
      formatList = resp['response']['docs'][0]['format']
      # Format specs can be given above as arrays or string values
      expect(formatList).to be == Array.wrap(formatValue)
    end
  end
end

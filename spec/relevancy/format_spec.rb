# -*- encoding : utf-8 -*-
require 'spec_helper'


# Fix up Computer Program, Computer File, etc.
# NEXT-970 - Some bibs assigned format "Computer File" instead of "Other"
describe 'Format assignments for types of "Computer Files"' do

  it "Double format:  Computer File and Online" do
    bibList = [ 2972693, 3105451, 3120827 ]
    bibList.each { |bib|
      resp = solr_response({'q'=>"id:#{bib}", 'fl'=>'id,format', 'facet'=>false})
      formatList = resp["response"]["docs"][0]["format"]
      # Assert the precise list of formats
      formatList.should == ['Computer File', 'Online']
      # Assert the presence of each format
      # resp.should include("format" => 'Computer File')
      # resp.should include("format" => 'Online')
    }

  end

  it "Single format:  Computer File" do
    bibList = [ 2996414, 3041516, 3238417, 3359137 ]
    bibList.each { |bib|
      resp = solr_response({'q'=>"id:#{bib}", 'fl'=>'id,format', 'facet'=>false})
      formatList = resp["response"]["docs"][0]["format"]
      formatList.should == ['Computer File']
    }
  end

  it "Single format:  Computer Program" do
    bibList = [ 519699, 519712, 620786, 705052, 742254, 959054, 1242420, 8617143 ]
    bibList.each { |bib|
      resp = solr_response({'q'=>"id:#{bib}", 'fl'=>'id,format', 'facet'=>false})
      formatList = resp["response"]["docs"][0]["format"]
      formatList.should == ['Computer Program']
    }
  end


end

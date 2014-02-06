require 'spec_helper'

describe "Summon Interface " do

  it "will use appropriate language in the links to full text" do
    # Turn this URL (multiple s.fvf) into Rails code
    # http://localhost:3000/articles?s.fvf[]=IsFullText,true&s.fvf[]=ContentType,Audio+Recording&q=
    
    visit articles_index_path( 'q' =>  '',
        's.fvf'    => [ 'IsFullText,true', 'ContentType,Audio Recording'] )
    all('div.details').each do |detail|
      detail.should have_text("Audio Recording: Available Online")
    end

    visit articles_index_path( 'q' =>  '',
        's.fvf'    => [ 'IsFullText,true', 'ContentType,Music Recording'] )
    all('div.details').each do |detail|
      detail.should have_text("Music Recording: Available Online")
    end

    visit articles_index_path( 'q' =>  '',
        's.fvf'    => [ 'IsFullText,true', 'ContentType,Journal Article'] )
    all('div.details').each do |detail|
      detail.should have_text("Journal Article: Full Text Available")
    end

    visit articles_index_path( 'q' =>  '',
        's.fvf'    => [ 'IsFullText,true', 'ContentType,Patent'] )
    all('div.details').each do |detail|
      detail.should have_text("Patent: Full Text Available")
    end
    
    # CERN LHC CMS Collaboration
    
  end

  it "will cut-off the list of authors at a certain point" do
    visit articles_index_path( 'q' =>  'CERN LHC CMS Collaboration')
    # The "more" note is at the end of the Author field - just before
    # the Citation field
    all('div.details').first.should have_text("(more...) Citation")
  end

end


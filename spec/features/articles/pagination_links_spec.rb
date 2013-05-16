require 'spec_helper'

describe "An articles search" do

  it "will have a next link that links to articles" do 
    visit articles_index_path('q' => 'test')
    page.should have_css('.sortAndPerPage a', :text => "Next")
    el = all('.sortAndPerPage a', :text => "Next").first
    el['href'].should include('/articles')
  end


  it "will be able to traverse next and previous links" do
    visit articles_index_path('q' => 'test')

    page.should_not have_css('.sortAndPerPage a', :text => "Previous")
    page.should have_css('.sortAndPerPage a', :text => "Next")

    all('.sortAndPerPage a', :text => "Next").first.click

    

    page.should have_css('.sortAndPerPage a', :text => "Previous")
    page.should have_css('.sortAndPerPage a', :text => "Next")

    all('.sortAndPerPage a', :text => "Previous").first.click

    page.should_not have_css('.sortAndPerPage a', :text => "Previous")
    page.should have_css('.sortAndPerPage a', :text => "Next")
  end
end


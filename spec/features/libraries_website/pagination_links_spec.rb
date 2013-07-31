require 'spec_helper'

describe "A Libraries Website search" do

  it "will have a next link that links to library_web" do
    visit library_web_index_path('q' => 'books')
    page.should have_css('.sortAndPerPage a', :text => "Next")
    el = all('.sortAndPerPage a', :text => "Next").first
    el['href'].should include('/library_web')
  end


  it "will be able to traverse next and previous links" do
    visit library_web_index_path('q' => 'books')

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


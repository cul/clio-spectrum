require 'spec_helper'

describe "The home page" do
  it "should display search fields for the archives, catalog, and new arrivals" do
    visit root_path
    page.should have_css(".search_box.catalog option")
    page.should have_css(".search_box.new_arrivals option")
    page.should have_css(".search_box.academic_commons option")
    pending("ejournal titles implementation")
    page.should have_css(".search_box.ejournals option")
  end
end

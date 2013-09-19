require 'spec_helper'

describe "All datasource labels should display correctly on home-page" do
  it "including Libraries Website" do
    visit root_path
    find('#datasources').should have_text("Libraries Website")
  end
end

describe "All of the datasources should successfully display results", :js => true do

  it "including quicksearch" do
    visit quicksearch_index_path('q' => 'test')
    page.should have_css(".result_set", :count => 4)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end
  end

  it "including catalog" do
    visit catalog_index_path('q' => 'test')
    page.should have_css('.result')
  end

  it "including articles" do
    visit articles_index_path('q' => 'test')
    page.should have_css('.result')
  end

  it "including ejournals" do
    visit journals_index_path('q' => 'test')
    page.should have_css('.result')
  end

  it "including databases" do
    visit databases_index_path('q' => 'test')
    page.should have_css('.result')
  end

  it "including academic commons" do
    visit academic_commons_index_path('q' => 'test')
    page.should have_css('.result')
  end

  it "including the library web site" do
    visit library_web_index_path('q' => 'test')
    page.should have_css('.result')
  end

  it "including the archives" do
    visit archives_index_path('q' => 'test')
    page.should have_css('.result')
  end

  it "including the dissertations" do
    visit dissertations_index_path('q' => 'test')
    page.should have_css(".result_set", :count => 3)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end
  end

  it "including the ebooks" do
    visit ebooks_index_path('q' => 'test')
    page.should have_css(".result_set", :count => 2)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end
  end

  it "including the new arrivals" do
    visit new_arrivals_index_path('q' => 'test')
    page.should have_css('.result')
  end

  it "including the newspapers" do
    visit newspapers_index_path('q' => 'test')
    page.should have_css('.result')
  end
end


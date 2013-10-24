require 'spec_helper'

describe "Datasource Sanity", :js => true do

  it "LWeb should be labeled 'Libraries Website'" do
    visit root_path
    find('#datasources').should have_text("Libraries Website")
  end

  it "direct datasources links should go to correct datasource landing pages" do

    visit '/quicksearch'
    find('.landing_main .title').should have_text('Quicksearch')

    visit '/catalog'
    find('.landing_main .title').should have_text('Catalog')

    visit '/articles'
    find('.landing_main .title').should have_text('Articles')

    visit '/journals'
    find('.landing_main .title').should have_text('E-Journal Titles')

    visit '/databases'
    find('.landing_main .title').should have_text('Databases')

    visit '/academic_commons'
    find('.landing_main .title').should have_text('Academic Commons')

    visit '/library_web'
    find('.landing_main .title').should have_text('Libraries Website')

    visit '/archives'
    find('.landing_main .title').should have_text('Archives')

    visit '/dissertations'
    find('.landing_main .title').should have_text('Dissertations')

    visit '/ebooks'
    find('.landing_main .title').should have_text('E-Books')

    visit '/new_arrivals'
    find('.landing_main .title').should have_text('New Arrivals')

    visit '/newspapers'
    find('.landing_main .title').should have_text('Newspapers')

  end

end



describe "Simple query should retrieve results ", :js => true do


  it "within all datasources" do

    visit quicksearch_index_path('q' => 'test')
    page.should have_css(".result_set", :count => 4)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end

    visit catalog_index_path('q' => 'test')
    page.should have_css('.result')

    visit articles_index_path('q' => 'test')
    page.should have_css('.result')

    visit journals_index_path('q' => 'test')
    page.should have_css('.result')

    visit databases_index_path('q' => 'test')
    page.should have_css('.result')

    visit academic_commons_index_path('q' => 'test')
    page.should have_css('.result')

    visit library_web_index_path('q' => 'test')
    page.should have_css('.result')

    visit archives_index_path('q' => 'test')
    page.should have_css('.result')

    visit dissertations_index_path('q' => 'test')
    page.should have_css(".result_set", :count => 3)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end

    visit ebooks_index_path('q' => 'test')
    page.should have_css(".result_set", :count => 2)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end

    visit new_arrivals_index_path('q' => 'test')
    page.should have_css('.result')

    visit newspapers_index_path('q' => 'test')
    page.should have_css('.result')
  end
end


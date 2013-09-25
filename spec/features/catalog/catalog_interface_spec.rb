require 'spec_helper'

describe "Catalog Search" do

  # NEXT-779 - Some 880 fields not showing up
  it "Advanced should default to 'All Fields'", :js => true do
    # visit this specific item
    visit catalog_path('7814900')

    # Find the 880 data for bib 7814900 within the info display
    find('.info').should have_content("Other Information: Leaf 1 contains laws on the Torah reading")
  end


  # NEXT-917 - Summary showing up twice for video records
  it "should show Summary only once for video records", :js => true do
    visit catalog_index_path('q' => 'summary')
    within 'div.blacklight-format ul' do
      find('a.more_facets_link').click
    end
    within 'ul.facet_extended_list' do
      click_link('Video')
    end

    within all('.result.document').first do
      all('a').first.click
    end
    page.should have_css('div.field', :text => 'Summary', :count => 1)
  end
end


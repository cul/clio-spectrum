require 'spec_helper'

describe "Catalog Interface" do

  # NEXT-779 - Some 880 fields not showing up
  it "Advanced Search should default to 'All Fields'", :js => true do
    # visit this specific item
    visit catalog_path('7814900')

    # Find the 880 data for bib 7814900 within the info display
    find('.info').should have_content("Other Information: Leaf 1 contains laws on the Torah reading")
  end


  # NEXT-917 - Summary showing up twice for video records
  it "Video Records should show Summary only once", :js => true do
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

  # NEXT-551 - display 'version of resource' and 'related resource' notes
  # this test is awefully tight - any cataloging/labeling change will break it.
  it "Item Links should show 'version of resource' and 'related resource'", :js => true do
    # on the search-results page
    visit catalog_index_path('q' => 'Introduction to high-energy astrophysics stephan rosswog')
    page.should have_text("Table of contents (version of resource)")
    page.should have_text("Publisher description (related resource)")

    # on the item-detail page
    click_link('Introduction to high-energy astrophysics')
    page.should have_text("Table of contents (version of resource)")
    page.should have_text("Publisher description (related resource)")
  end

  # NEXT-619 - improvements to 'Manuscript' facet
  it "Should find many Manuscripts for Call Number range X893", :js => true do
    visit catalog_index_path('q' => 'X893')
    within '.search_box.catalog' do
      find('btn.dropdown-toggle').click()
      within '.dropdown-menu' do
        click_link("Call Number")
      end
      find('button[type=submit]').click()
    end
    within 'div.blacklight-format ul' do
      click_link('Manuscript/Archive')
    end
    # exact count depends on default items-per-page, today, 25
    page.should have_css('.result.document', :count => 25)
    # matching "1", or "1N", or "1NN"...  the value today is actually 1504
    page.should have_text('1 - 25 of 1')
  end


  # NEXT-640 - Records in CLIO should include links to Hathi Trust
  it "Should show Hathi Trust links, both 'Full view' and 'Limited'", :js => true do
    # visit this specific item
    visit catalog_path('3430925')

    # Should see the 'Full View' message in the Hathi Holdings box
    find('#hathi_holdings .hathi_info #hathidata').should have_content("Full view")

    # visit this specific item
    visit catalog_path('70744')

    # Should see the 'Limited (search-only)' message in the Hathi Holdings box
    find('#hathi_holdings .hathi_info #hathidata').should have_content("Limited (search-only)")
  end


  # NEXT-931 - Online Links in Holdings (not in the Bib) should display
  it "Online links from Bib or Holdings should show up within correct block", :js => true do
    # visit this specific item
    visit catalog_path('382300')

    # within CLIO HOLDINGS, not the regular Online div...
    # ...should see an 'Online' block
    find('div#clio_holdings').
      should have_content("Online")
    # ...should see the specific URL...
    find('div#clio_holdings').
      should have_content("http://www.neighborhoodpreservationcenter.org/")

    # And, contrariwise, other Avery Online material, which does not have
    # an 856 URL in the Holdings record, should display 'Online' within the 
    # visit this specific item
    visit catalog_path('10099362')

    # within ONLINE HOLDINGS, SHOULD see an 'Online' block
    find('div#online_holdings').should have_content("Online")

    # within CLIO HOLDINGS, should NOT see an 'Online' block
    find('div#clio_holdings').should_not have_content("Online")
  end


end


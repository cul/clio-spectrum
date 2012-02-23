describe "The home page" do
  it "should display search fields for the archives, catalog, databases, and new arrivals" do
    visit root_path
    sources_to_check = %w{archives catalog new_arrivals databases academic_commons}
    sources_to_check.each do |source|
      page.should have_css(".search_box.#{source} option") 
    end
  end
end

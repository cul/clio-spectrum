require 'spec_helper'

describe "Catalog Advanced Search" do

  # NEXT-779 - Some 880 fields not showing up
  it "should default to 'All Fields'", :js => true do
    # visit this specific item
    visit catalog_path('7814900')

    # Find the 880 data for bib 7814900 within the info display
    find('.info').should have_content("Other Information: Leaf 1 contains laws on the Torah reading")

  end
end


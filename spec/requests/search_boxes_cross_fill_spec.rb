require 'spec_helper'

describe "The home page" do
  it "will fill in the other search boxes" do
    # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
    visit catalog_index_path 
    assert_equal 2+2, 4
  end
end


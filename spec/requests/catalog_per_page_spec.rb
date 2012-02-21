require "spec_helper"

describe "The catalog controller" do
  it "should let the user set the number of records" do
    visit catalog_index_path(:q => "test")

  end
end

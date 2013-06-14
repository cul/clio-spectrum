require 'spec_helper'

describe "list_items/show" do
  before(:each) do
    @list_item = assign(:list_item, stub_model(ListItem,
      :list_id => 1,
      :item_key => "Item Key",
      :sort_order => 2
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/Item Key/)
    rendered.should match(/2/)
  end
end

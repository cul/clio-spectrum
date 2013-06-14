require 'spec_helper'

describe "list_items/index" do
  before(:each) do
    assign(:list_items, [
      stub_model(ListItem,
        :list_id => 1,
        :item_key => "Item Key",
        :sort_order => 2
      ),
      stub_model(ListItem,
        :list_id => 1,
        :item_key => "Item Key",
        :sort_order => 2
      )
    ])
  end

  it "renders a list of list_items" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Item Key".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
  end
end

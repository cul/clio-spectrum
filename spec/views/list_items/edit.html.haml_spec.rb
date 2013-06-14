require 'spec_helper'

describe "list_items/edit" do
  before(:each) do
    @list_item = assign(:list_item, stub_model(ListItem,
      :list_id => 1,
      :item_key => "MyString",
      :sort_order => 1
    ))
  end

  it "renders the edit list_item form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", list_item_path(@list_item), "post" do
      assert_select "input#list_item_list_id[name=?]", "list_item[list_id]"
      assert_select "input#list_item_item_key[name=?]", "list_item[item_key]"
      assert_select "input#list_item_sort_order[name=?]", "list_item[sort_order]"
    end
  end
end

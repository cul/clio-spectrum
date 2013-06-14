require 'spec_helper'

describe "list_items/new" do
  before(:each) do
    assign(:list_item, stub_model(ListItem,
      :list_id => 1,
      :item_key => "MyString",
      :sort_order => 1
    ).as_new_record)
  end

  it "renders new list_item form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", list_items_path, "post" do
      assert_select "input#list_item_list_id[name=?]", "list_item[list_id]"
      assert_select "input#list_item_item_key[name=?]", "list_item[item_key]"
      assert_select "input#list_item_sort_order[name=?]", "list_item[sort_order]"
    end
  end
end

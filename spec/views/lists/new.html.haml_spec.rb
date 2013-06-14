require 'spec_helper'

describe "lists/new" do
  before(:each) do
    assign(:list, stub_model(List,
      :name => "MyString",
      :description => "MyString",
      :created_by => "MyString",
      :permissions => "MyString"
    ).as_new_record)
  end

  it "renders new list form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", lists_path, "post" do
      assert_select "input#list_name[name=?]", "list[name]"
      assert_select "input#list_description[name=?]", "list[description]"
      assert_select "input#list_created_by[name=?]", "list[created_by]"
      assert_select "input#list_permissions[name=?]", "list[permissions]"
    end
  end
end

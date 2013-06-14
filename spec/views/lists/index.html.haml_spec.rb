require 'spec_helper'

describe "lists/index" do
  before(:each) do
    assign(:lists, [
      stub_model(List,
        :name => "Name",
        :description => "Description",
        :created_by => "Created By",
        :permissions => "Permissions"
      ),
      stub_model(List,
        :name => "Name",
        :description => "Description",
        :created_by => "Created By",
        :permissions => "Permissions"
      )
    ])
  end

  it "renders a list of lists" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    assert_select "tr>td", :text => "Created By".to_s, :count => 2
    assert_select "tr>td", :text => "Permissions".to_s, :count => 2
  end
end

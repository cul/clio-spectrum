require 'spec_helper'

describe "lists/show" do
  before(:each) do
    @list = assign(:list, stub_model(List,
      :name => "Name",
      :description => "Description",
      :created_by => "Created By",
      :permissions => "Permissions"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Description/)
    rendered.should match(/Created By/)
    rendered.should match(/Permissions/)
  end
end

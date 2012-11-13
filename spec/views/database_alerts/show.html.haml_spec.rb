require 'spec_helper'

describe "database_alerts/show" do
  before(:each) do
    @database_alert = assign(:database_alert, stub_model(DatabaseAlert))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end

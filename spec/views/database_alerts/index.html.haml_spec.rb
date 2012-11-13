require 'spec_helper'

describe "database_alerts/index" do
  before(:each) do
    assign(:database_alerts, [
      stub_model(DatabaseAlert),
      stub_model(DatabaseAlert)
    ])
  end

  it "renders a list of database_alerts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end

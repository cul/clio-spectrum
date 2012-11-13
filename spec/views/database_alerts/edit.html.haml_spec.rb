require 'spec_helper'

describe "database_alerts/edit" do
  before(:each) do
    @database_alert = assign(:database_alert, stub_model(DatabaseAlert))
  end

  it "renders the edit database_alert form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => database_alerts_path(@database_alert), :method => "post" do
    end
  end
end

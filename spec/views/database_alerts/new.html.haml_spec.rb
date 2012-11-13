require 'spec_helper'

describe "database_alerts/new" do
  before(:each) do
    assign(:database_alert, stub_model(DatabaseAlert).as_new_record)
  end

  it "renders new database_alert form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => database_alerts_path, :method => "post" do
    end
  end
end

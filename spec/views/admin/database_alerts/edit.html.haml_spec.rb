require 'spec_helper'

describe "admin_database_alerts/edit" do
  before(:each) do
    @database_alert = assign(:database_alert, stub_model(Admin::DatabaseAlert,
      :clio_id => 1,
      :author_id => 1,
      :active => false,
      :message => "MyText"
    ))
  end

  it "renders the edit database_alert form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => admin_database_alerts_path(@database_alert), :method => "post" do
      assert_select "input#database_alert_clio_id", :name => "database_alert[clio_id]"
      assert_select "input#database_alert_author_id", :name => "database_alert[author_id]"
      assert_select "input#database_alert_active", :name => "database_alert[active]"
      assert_select "textarea#database_alert_message", :name => "database_alert[message]"
    end
  end
end

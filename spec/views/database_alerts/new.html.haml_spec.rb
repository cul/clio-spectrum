require 'spec_helper'

describe "database_alerts/new" do
  before(:each) do
    assign(:database_alert, stub_model(DatabaseAlert,
      :clio_id => 1,
      :author_id => 1,
      :active => false,
      :message => "MyText"
    ).as_new_record)
  end

  it "renders new database_alert form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => database_alerts_path, :method => "post" do
      assert_select "input#database_alert_clio_id", :name => "database_alert[clio_id]"
      assert_select "input#database_alert_author_id", :name => "database_alert[author_id]"
      assert_select "input#database_alert_active", :name => "database_alert[active]"
      assert_select "textarea#database_alert_message", :name => "database_alert[message]"
    end
  end
end

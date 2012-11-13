require 'spec_helper'

describe "item_alerts/new" do
  before(:each) do
    assign(:item_alert, stub_model(ItemAlert,
      :source => "MyString",
      :item_key => "MyString",
      :alert_type => "MyString",
      :author_id => 1,
      :message => "MyText"
    ).as_new_record)
  end

  it "renders new item_alert form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => item_alerts_path, :method => "post" do
      assert_select "input#item_alert_source", :name => "item_alert[source]"
      assert_select "input#item_alert_item_key", :name => "item_alert[item_key]"
      assert_select "input#item_alert_alert_type", :name => "item_alert[alert_type]"
      assert_select "input#item_alert_author_id", :name => "item_alert[author_id]"
      assert_select "textarea#item_alert_message", :name => "item_alert[message]"
    end
  end
end

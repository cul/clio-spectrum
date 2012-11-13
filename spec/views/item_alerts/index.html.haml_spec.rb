require 'spec_helper'

describe "item_alerts/index" do
  before(:each) do
    assign(:item_alerts, [
      stub_model(ItemAlert,
        :source => "Source",
        :item_key => "Item Key",
        :alert_type => "Alert Type",
        :author_id => 1,
        :message => "MyText"
      ),
      stub_model(ItemAlert,
        :source => "Source",
        :item_key => "Item Key",
        :alert_type => "Alert Type",
        :author_id => 1,
        :message => "MyText"
      )
    ])
  end

  it "renders a list of item_alerts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Source".to_s, :count => 2
    assert_select "tr>td", :text => "Item Key".to_s, :count => 2
    assert_select "tr>td", :text => "Alert Type".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end

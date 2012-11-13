require 'spec_helper'

describe "item_alerts/show" do
  before(:each) do
    @item_alert = assign(:item_alert, stub_model(ItemAlert,
      :source => "Source",
      :item_key => "Item Key",
      :alert_type => "Alert Type",
      :author_id => 1,
      :message => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Source/)
    rendered.should match(/Item Key/)
    rendered.should match(/Alert Type/)
    rendered.should match(/1/)
    rendered.should match(/MyText/)
  end
end

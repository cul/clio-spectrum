require 'spec_helper'

describe "admin_database_alerts/index" do
  before(:each) do
    assign(:admin_database_alerts, [
      stub_model(Admin::DatabaseAlert,
        :clio_id => 1,
        :author_id => 2,
        :active => false,
        :message => "MyText"
      ),
      stub_model(Admin::DatabaseAlert,
        :clio_id => 1,
        :author_id => 2,
        :active => false,
        :message => "MyText"
      )
    ])
  end

  it "renders a list of admin_database_alerts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end

require 'spec_helper'

describe "database_alerts/show" do
  before(:each) do
    @database_alert = assign(:database_alert, stub_model(DatabaseAlert,
      :clio_id => 1,
      :author_id => 2,
      :active => false,
      :message => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/false/)
    rendered.should match(/MyText/)
  end
end

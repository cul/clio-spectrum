require 'rails_helper'

RSpec.describe "preferences/index", type: :view do
  before(:each) do
    assign(:preferences, [
      Preference.create!(
        :login => "Login",
        :settings => "MyText"
      ),
      Preference.create!(
        :login => "Login",
        :settings => "MyText"
      )
    ])
  end

  it "renders a list of preferences" do
    render
    assert_select "tr>td", :text => "Login".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end

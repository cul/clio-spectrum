require 'rails_helper'

RSpec.describe "preferences/new", type: :view do
  before(:each) do
    assign(:preference, Preference.new(
      :login => "MyString",
      :settings => "MyText"
    ))
  end

  it "renders new preference form" do
    render

    assert_select "form[action=?][method=?]", preferences_path, "post" do

      assert_select "input#preference_login[name=?]", "preference[login]"

      assert_select "textarea#preference_settings[name=?]", "preference[settings]"
    end
  end
end

require 'rails_helper'

RSpec.describe "preferences/edit", type: :view do
  before(:each) do
    @preference = assign(:preference, Preference.create!(
      :login => "MyString",
      :settings => "MyText"
    ))
  end

  it "renders the edit preference form" do
    render

    assert_select "form[action=?][method=?]", preference_path(@preference), "post" do

      assert_select "input#preference_login[name=?]", "preference[login]"

      assert_select "textarea#preference_settings[name=?]", "preference[settings]"
    end
  end
end

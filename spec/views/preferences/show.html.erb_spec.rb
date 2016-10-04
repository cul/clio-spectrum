require 'rails_helper'

RSpec.describe "preferences/show", type: :view do
  before(:each) do
    @preference = assign(:preference, Preference.create!(
      :login => "Login",
      :settings => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Login/)
    expect(rendered).to match(/MyText/)
  end
end

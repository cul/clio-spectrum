require 'spec_helper'

describe 'Top nav menus' do

  # NEXT-986 - Redirect CLIO Help menu link
  it 'should link CLIO Help to blog guides page', :vcr do
    visit root_path
    within('#topnavbar') do
      within('.dropdown.menu', :text => "Help") do
        click_link "Help"
        expect(find('.dropdown-menu')).to have_link('CLIO Help', :href => 'https://blogs.cul.columbia.edu/clio/guides/')
      end
    end
  end

end

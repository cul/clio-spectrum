require 'spec_helper'

describe 'Invalid byte sequences should be caught' do

  it 'in CGI params' do
    # Send bytes that are NOT valid in UTF-8...
    visit '/catalog?q=foo%E2%EF%BF%BD%A6'

    # We SHOULD have added middleware to deal with this,
    # which should land us on a valid search-results page.
    expect(page).to have_text('You searched for')
  end

end

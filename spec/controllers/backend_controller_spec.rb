require 'spec_helper'

describe BackendController do
  # BackendController doesn't have an interface that can be excercised
  #  with feature tests.  We'll test html content here with controller
  #  specs although we maybe should setup request-specs for this.
  render_views

  before(:all) do
    APP_CONFIG['saved_backend_url'] = APP_CONFIG['clio_backend_url']
  end

  after(:all) do
    APP_CONFIG['clio_backend_url'] = APP_CONFIG['saved_backend_url']
  end

  # # NEXT-1009 - Multiple 866 fields in the holding records
  # it "holdings with multiple 866s" do
  #   get 'holdings', :id => '763577'
  #   expect(response).to be_successful
  #   expect(response.body).to_not match /\-\-/
  #   expect(response.body).to match /<br\/>Special issues/
  # end
  #
  # # NEXT-1147 - Add location note for Burke rare locations
  # it "should include location_notes in holdings" do
  #   bibs = [5951061, 6703227, 9020317, 10654375, 4584787]
  #   location_note = 'By appointment only. See the Burke Library special collections page'
  #   link_text = 'Burke Library special collections page'
  #   link_href = 'https://library.columbia.edu/locations/burke/access_circulation/special-collections-access.html'
  #
  #   bibs.each do |bib|
  #     get 'holdings', :id => bib
  #     expect(response).to be_successful
  #     expect(response.body).to have_text location_note
  #     expect(response.body).to have_link(link_text, href: link_href)
  #   end
  # end
  #
  #
  # # NEXT-988 - Label the Call Number field
  # it "should label Call Numbers" do
  #   # Simple case
  #   get 'holdings', :id => '123456'
  #   expect(response).to be_successful
  #   tagless = response.body.gsub(/<\/?[^>]+>/, '')
  #   expect(tagless).to match /Call Number:\s+HD1945/m
  #
  #   # Complex case
  #   get 'holdings', :id => '763577'
  #   expect(response).to be_successful
  #   tagless = response.body.gsub(/<\/?[^>]+>/, '')
  #   expect(tagless).to match /Call Number:\s+R341.273/m
  #   expect(tagless).to match /Call Number:\s+JX233/m
  #   expect(tagless).to match /Call Number:\s+MICFICHE/m
  # end
  #
  # it "holdings() should return silently absorb non-numeric CLIO ID" do
  #   # non-numeric value
  #   get 'holdings', :id => 'non-numeric'
  #   expect(response).to be_successful
  #   expect(response.body.strip).to be_empty
  # end
  #
  # it "holdings() should fail on out-of-integer-range CLIO ID" do
  #   # really, really big integer
  #   get 'holdings', :id => '999999999999999999999999999999999999'
  #   expect(response.status).to eq 400
  #   expect(response.body.strip).to be_empty
  # end
  #
  # it "should refuse to route without an ID filled in" do
  #
  #   expect {
  #     # nil
  #     get 'holdings', :id => nil
  #   }.to raise_error(ActionController::UrlGenerationError)
  #
  #   expect {
  #     # nil
  #     get 'holdings'
  #   }.to raise_error(ActionController::UrlGenerationError)
  #
  # end
  #
  # it "holdings() against an invalid back-end app path should fail" do
  #   APP_CONFIG['clio_backend_url'] = APP_CONFIG['clio_backend_url'] + "/foo/bar"
  #   get 'holdings', :id => '123'
  #   expect(response.status).to eq 400
  #   expect(response.body.strip).to be_empty
  # end
  #
  #
  #
  # it "holdings() against an invalid back-end hostname should fail" do
  #   APP_CONFIG['clio_backend_url'] = 'http://no.such.host'
  #   get 'holdings', :id => '123'
  #   expect(response.status).to eq 400
  #   expect(response.body.strip).to be_empty
  # end
  #
  #
  # it "holdings() against an unroutable back-end IP should fail" do
  #   APP_CONFIG['clio_backend_url'] = 'http://999.999.999.999'
  #   get 'holdings', :id => '123'
  #   expect(response.status).to eq 400
  #   expect(response.body.strip).to be_empty
  # end

  it 'url_for_id() should raise RuntimeError if when clio_backend_url unset' do
    expect do
      be = BackendController.new
      APP_CONFIG.delete('clio_backend_url')
      be.url_for_id(123)
    end.to raise_error(RuntimeError)
  end
end

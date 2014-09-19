require 'spec_helper'

describe 'Zotero Encoding' do
  context 'item view' do
    it 'has the correct coins for an audio recording' do
      visit 'http://clio.columbia.edu/catalog/10922430'
      coins = CGI.unescape find("//span[@class='Z3988']")['title']
      expect(coins).to match(/fmt:kev:mtx:dc&rft\.type=audioRecording/)
    end
  end
  context 'search results view' do
    it 'has the correct coins for an audio recording' do
      visit 'http://clio.columbia.edu/catalog?q=psalm+21+meyerbeer'
      coins = all "//span[@class='Z3988']"
      coins.each do |coin|
        expect(CGI.unescape (coin)['title']).to match(/fmt:kev:mtx:dc&rft\.type=audioRecording/)
      end
    end
  end
end

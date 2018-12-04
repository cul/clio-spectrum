require 'spec_helper'

describe 'Virtual Shelf Browse', vcr: { allow_playback_repeats: true } do
  # NEXT-995 - Something like "shelf view"
  it 'should show basic controls on first load of simple item', :js do
    # pull up a simple item-detail page
    visit solr_document_path(1234)
    # verify some basic labels and buttons
    expect(find('#mini_browse_panel')).to have_text(I18n.t('blacklight.browse.label'))
    expect(find('.btn.show_mini_browse', text: 'Show')).not_to have_css('disabled')
    find('.btn.hide_mini_browse.disabled', text: 'Hide')
    expect(find('.btn.full_screen_link')).to have_text(I18n.t('blacklight.browse.full_screen'))
    # verify that there's no browse-list showing yet
    expect(page).to_not have_css('#mini_browse_list')
  end

  it 'should show browse list upon button click', :js do
    # pull up simple item-detail page, click to Show the browse-list
    visit solr_document_path(1234)
    find('.btn.show_mini_browse', text: 'Show').click

    expect(page).to have_css('#nearby .nearby_content')

    within('#nearby .nearby_content') do
      # Search for control labels specific to bib 1234
      expect(first('nav.index_toolbar')).to have_text('« Previous | PN45')
      expect(first('nav.index_toolbar')).to have_text(' - PN45 .R')
      expect(first('nav.index_toolbar')).to have_text('Return to PN45')
      expect(page).to have_css('.document.result', count: 10)

      # The current item (bib 1234) should be 3rd in the list.
      browse_items = page.all('.document.result')
      expect(browse_items[2]).to have_text('The reader, the text, the poem')
      expect(browse_items[2][:item_id]).to eq '1234'
      expect(browse_items[2][:class]).to match(/browse_focus/)
    end
  end

  # NEXT-1150 - message for items which cannot launch virtual shelf browse
  it 'should display special text for items without call-numbers' do
    unavailable_text = I18n.t('blacklight.browse.unavailable')
    # offsite, no call number assigned - should be durable for testing
    visit solr_document_path(102437)
    expect(page).to have_text(unavailable_text)
  end
end

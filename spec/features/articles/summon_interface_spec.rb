require 'spec_helper'

describe 'Summon Interface' do
  context 'use appropriate language in the links to full text' do
    # Turn this URL (multiple s.fvf) into Rails code
    # http://localhost:3000/articles?s.fvf[]=IsFullText,true&s.fvf[]=ContentType,Audio+Recording&q=

    it 'audio recordings' do
      visit articles_index_path('q' => '',
                                's.fvf'    => ['IsFullText,true', 'ContentType,Audio Recording'])
      # We should find at least one of these...
      expect(page).to have_css('div.details')
      # and each one we find must satisfy this assertion.
      all('div.details').each do |detail|
        expect(detail).to have_text('Audio Recording: Available Online')
      end
    end

    it 'audio recordings' do
      visit articles_index_path('q' => '',
                                's.fvf'    => ['IsFullText,true', 'ContentType,Audio Recording'])
      expect(page).to have_css('div.details')
      all('div.details').each do |detail|
        expect(detail).to have_text 'Audio Recording: Available Online'
      end
    end

    it 'journal articles' do
      visit articles_index_path('q' => '',
                                's.fvf'    => ['IsFullText,true', 'ContentType,Journal Article'])
      expect(page).to have_css('div.details', count: 10)
      all('div.details').each do |detail|
        # detail node contains full descriptive data - author, citaion, format, etc.
        expect(detail.text).to satisfy { |detail_text|
          # Summon's precise language seems to be flip-flopping today,
          #  any of these might show up.
          # TOO MANY...
          # detail_text.match(/Journal Article: Full Text Available/) ||
          # detail_text.match(/Book Chapter: Full Text Available/) ||
          # detail_text.match(/Book Review: Full Text Available/) ||
          # detail_text.match(/Conference Proceeding: Full Text Online/) ||
          # detail_text.match(/Conference Proceeding: Full Text Available/)
          # JUST TEST THE FINAL WORDS...
          detail_text.match(/: Full Text Online/) ||
            detail_text.match(/: Full Text Available/)
        }
      end
    end

    it 'patents' do
      visit articles_index_path('q' => 'patent',
                                's.fvf'    => ['IsFullText,true', 'ContentType,Patent'])
      expect(page).to have_css('div.details')
      all('div.details').each do |detail|
        expect(detail).to have_text('Patent: Full Text Available')
      end
    end
  end

  # CERN LHC CMS Collaboration
  it 'will cut-off the list of authors at a certain point' do
    title = 'The CMS experiment at the CERN LHC'
    title_field = 's.fq[TitleCombined]'
    visit articles_index_path(q: title, search_field: title_field)
    # The "more" note is at the end of the Author field - just before
    # the Citation field
    expect(all('div.details').first).to have_text('(more...) Citation')
  end
end

describe 'Summon searches' do
  it 'should remember items-per-page' do
    # SET initial page-size to 50 items
    visit articles_index_path('q' => 'frog')
    within all('.index_toolbar.navbar').first do
      find('.dropdown-toggle', text: 'Display Options').click
      click_link 'Display Options'
      click_link '50 per page'
      # expect(page).to have_text '1 - 50 of'
    end

    # Confirm 50-items returned upon next search
    visit articles_index_path('q' => 'horse')
    within all('.index_toolbar.navbar').first do
      expect(find('#current_item_info')).to have_text '1 - 50 of'
    end

    # SET page-size to new value, 10 items
    within all('.index_toolbar.navbar').first do
      find('.dropdown-toggle', text: 'Display Options').click
      click_link 'Display Options'
      click_link '10 per page'
      # expect(find('#current_item_info')).to have_text '1 - 10 of'
    end

    # Confirm 10-items returned upon next search
    visit articles_index_path('q' => 'pig')
    within all('.index_toolbar.navbar').first do
      expect(find('#current_item_info')).to have_text '1 - 10 of'
    end
  end
end

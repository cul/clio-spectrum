require 'spec_helper'

describe 'Summon Interface ' do

  it 'will use appropriate language in the links to full text' do
    # Turn this URL (multiple s.fvf) into Rails code
    # http://localhost:3000/articles?s.fvf[]=IsFullText,true&s.fvf[]=ContentType,Audio+Recording&q=

    visit articles_index_path('q' =>  '',
                              's.fvf'    => ['IsFullText,true', 'ContentType,Audio Recording'])
    # We should find at least one of these...
    expect(find(page)).to have_css('div.details')
    # and each one we find must satisfy this assertion.
    all('div.details').each do |detail|
      detail.should have_text('Audio Recording: Available Online')
    end

    visit articles_index_path('q' =>  '',
                              's.fvf'    => ['IsFullText,true', 'ContentType,Music Recording'])
    expect(find(page)).to have_css('div.details')
    all('div.details').each do |detail|
      detail.should have_text('Music Recording: Available Online')
    end

    visit articles_index_path('q' =>  '',
                              's.fvf'    => ['IsFullText,true', 'ContentType,Journal Article'])
    expect(find(page)).to have_css('div.details')
    all('div.details').each do |detail|
      # detail node contains full descriptive data - author, citaion, format, etc.
      detail.text.should satisfy { |detail_text|
        # Summon's precise language seems to be flip-flopping today,
        #  any of these might show up.
        detail_text.match(/Journal Article: Full Text Available/) ||
        detail_text.match(/Book Chapter: Full Text Available/) ||
        detail_text.match(/Conference Proceeding: Full Text Online/) ||
        detail_text.match(/Conference Proceeding: Full Text Available/)
      }
    end

    visit articles_index_path('q' =>  '',
                              's.fvf'    => ['IsFullText,true', 'ContentType,Patent'])
    expect(find(page)).to have_css('div.details')
    all('div.details').each do |detail|
      detail.should have_text('Patent: Full Text Available')
    end

    # CERN LHC CMS Collaboration

  end

  it 'will cut-off the list of authors at a certain point' do
    visit articles_index_path('q' =>  'CERN LHC CMS Collaboration')
    # The "more" note is at the end of the Author field - just before
    # the Citation field
    all('div.details').first.should have_text('(more...) Citation')
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
    end

    # Confirm 10-items returned upon next search
    visit articles_index_path('q' => 'pig')
    within all('.index_toolbar.navbar').first do
      expect(find('#current_item_info')).to have_text '1 - 10 of'
    end

  end

end

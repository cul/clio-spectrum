require 'spec_helper'
require 'rake'

describe 'Item Locations should show correct library hours', js: true, skip_travis: true do

  before(:all) do
    Location.clear_and_load_fixtures!

    Rake.application.rake_require 'tasks/solr_ingest'
    Rake.application.rake_require 'tasks/sync_hours'
    Rake::Task.define_task(:environment)
    Rake.application.invoke_task 'hours:sync'

    Location.clear_and_load_fixtures!

  end

  # I'm not sure... do I ever have to re-run the Rake tasks as part of the rspec?
  # before :all do
  #   Location.clear_and_load_fixtures!
  #   Rake.application.rake_require "tasks/solr_ingest"
  #   Rake.application.rake_require "tasks/sync_hours"
  #   Rake::Task.define_task(:environment)
  #   Rake.application.invoke_task "hours:sync"
  #   Location.clear_and_load_fixtures!
  # end

  it 'for Avery Drawings & Archives' do
    visit catalog_path('8277276')
    # page.save_and_open_page # debug
    expect(find('.holdings-container')).to have_text('Avery Drawings & Archives')
    click_link('Avery Drawings & Archives - By appt. (Non-Circulating)')
    # page.save_and_open_page # debug
    expect(page).to have_text('Avery Drawings & Archives')
    expect(page).to have_link('Full Hours Info', href: 'http://www.columbia.edu/cu/lweb/services/hours/index.html?library=avery-drawings-archives')
  end

  it 'for Avery Classics' do
    # Pull up the item-detail page, follow link to Location page...
    visit catalog_path('565036')
    expect(find('.holdings-container')).to have_text('Avery Classics')
    within('.location_box .location', text: 'Avery Classics') do
      click_link('Avery Classics')
    end

    # Check out the Location page...
    expect(page).to have_text('Avery Classics')
    expect(page).to have_link('Floorplans', href: 'http://library.columbia.edu/locations/avery/floorplans.html')
    expect(page).to have_link('Full Hours Info', href: 'http://www.columbia.edu/cu/lweb/services/hours/index.html?library=avery-classics')
  end

  it 'for Law' do
    visit catalog_path('b402660')
    expect(page).to have_text('Law Library')
    click_link('Law Library')
    expect(page).to have_text('Law Library')
    expect(page).to have_text('Arthur W. Diamond')
    expect(page).to have_text('Jerome Greene Hall')
    # page.save_and_open_page # debug
    expect(page).to have_link('Home Page', href: 'http://web.law.columbia.edu/library')
    expect(page).to have_link('Full Hours Info', href: 'http://www.columbia.edu/cu/lweb/services/hours/index.html?library=law')
  end

end

require 'spec_helper'

describe 'Datasource Sanity', js: true do

  it "LWeb should be labeled 'Libraries Website'" do
    visit root_path
    find('#datasources').should have_text('Libraries Website')
  end

  it 'direct datasources links should go to correct datasource landing pages' do

    visit '/quicksearch'
    find('.landing_main .title').should have_text('Quicksearch')

    visit '/catalog'
    find('.landing_main .title').should have_text('Catalog')

    visit '/articles'
    find('.landing_main .title').should have_text('Articles')

    visit '/journals'
    find('.landing_main .title').should have_text('E-Journal Titles')

    visit '/databases'
    find('.landing_main .title').should have_text('Databases')

    visit '/academic_commons'
    find('.landing_main .title').should have_text('Academic Commons')

    visit '/library_web'
    find('.landing_main .title').should have_text('Libraries Website')

    visit '/archives'
    find('.landing_main .title').should have_text('Archives')

    visit '/dissertations'
    find('.landing_main .title').should have_text('Dissertations')

    visit '/ebooks'
    find('.landing_main .title').should have_text('E-Books')

    visit '/new_arrivals'
    find('.landing_main .title').should have_text('New Arrivals')

    # visit '/newspapers'
    # find('.landing_main .title').should have_text('Newspapers')

  end

end

describe 'Simple query should retrieve results ', js: true do

  it 'within all datasources' do

    visit quicksearch_index_path('q' => 'test')
    expect(page).to have_css('.result_set', count: 4)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end

    visit catalog_index_path('q' => 'test')
    page.should have_css('.result')

    visit articles_index_path('q' => 'test')
    page.should have_css('.result')

    visit journals_index_path('q' => 'test')
    page.should have_css('.result')

    visit databases_index_path('q' => 'test')
    page.should have_css('.result')

    visit academic_commons_index_path('q' => 'test')
    page.should have_css('.result')

    visit library_web_index_path('q' => 'test')
    page.should have_css('.result')

    visit archives_index_path('q' => 'test')
    page.should have_css('.result')

    visit dissertations_index_path('q' => 'test')
    page.should have_css('.result_set', count: 3)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end

    visit ebooks_index_path('q' => 'test')
    page.should have_css('.result_set', count: 2)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end

    visit new_arrivals_index_path('q' => 'test')
    page.should have_css('.result')

    # visit newspapers_index_path('q' => 'test')
    # page.should have_css('.result')
  end

end

describe 'Switching between data-source', js: true do

  it 'should carry forward simple search to each datasource', XXfocus: true do
    visit root_path
    # page.save_and_open_page # debug
    # terminal newline submits form
    fill_in 'q', with: "test\n"

    page.should have_css('.result_set', count: 4)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end
    # page.save_and_open_page # debug

    within('#datasources') do
      click_link('Catalog')
    end
    find('div.constraint-box').should have_text('test')
    page.should have_css('.result')
    all('#documents .result').first['source'].should eq 'catalog'

    click_link('Articles')
    # find('input#articles_q').should have_text('test')
    find('input#articles_q').value.should eq 'test'
    find('.well-constraints').should have_text('test')
    page.should have_css('.result')
    # puts "==========" + all('#documents .result').first.inspect
    # all('#documents .result').first.should have_selector('.article_list')

    click_link('E-Journal Titles')
    find('input#journals_q').value.should eq 'test'
    find('.constraint-box').should have_text('test')
    page.should have_css('.result')
    all('#documents .result').first['source'].should eq 'catalog'

    click_link('Databases')
    find('input#databases_q').value.should eq 'test'
    find('.constraint-box').should have_text('test')
    page.should have_css('.result')
    all('#documents .result').first['source'].should eq 'catalog'

    click_link('Academic Commons')
    find('input#academic_commons_q').value.should eq 'test'
    find('.constraint-box').should have_text('test')
    page.should have_css('.result')
    all('#documents .result').first['source'].should eq 'academic_commons'

    click_link('Libraries Website')
    find('input#library_web_q').value.should eq 'test'
    find('.constraint-box').should have_text('test')
    page.should have_css('.result')
    # all('#documents .result').first['source'].should eq 'XXX'

    click_link('Archives')
    find('input#archives_q').value.should eq 'test'
    find('.constraint-box').should have_text('test')
    page.should have_css('.result')
    all('#documents .result').first['source'].should eq 'catalog'

    click_link('More...')
    click_link('Dissertations')
    find('input#dissertations_q').value.should eq 'test'
    page.should have_css('.result_set', count: 3)
    expect(page).to have_css('.result_count', count: 3)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end

    click_link('E-Books')
    find('input#ebooks_q').value.should eq 'test'
    page.should have_css('.result_set', count: 2)
    all('.result_set').each do |result_set|
      result_set.should have_css('.result')
    end

    click_link('New Arrivals')
    find('input#new_arrivals_q').value.should eq 'test'
    find('.constraint-box').should have_text('test')
    page.should have_css('.result')
    all('#documents .result').first['source'].should eq 'catalog'

    # click_link('More...')
    # click_link('Newspapers')
    # find('input#newspapers_q').value.should eq 'test'
    # find('.well-constraints').should have_text('test')
    # page.should have_css('.result')

  end

  # NEXT-978 - "Back" button broken in CLIO
  it 'should allow back/forward navigation' do
    visit root_path

    within('#datasources') do
      click_link('Catalog')
    end
    # page.save_and_open_page # debug
    find('.landing_main .title').should have_text('Catalog')

    within('#datasources') do
      click_link('Articles')
    end
    find('.landing_main .title').should have_text('Articles')

    within('#datasources') do
      click_link('Databases')
    end
    find('.landing_main .title').should have_text('Databases')

    page.evaluate_script('window.history.back()')
    find('.landing_main .title').should have_text('Articles')

    page.evaluate_script('window.history.back()')
    find('.landing_main .title').should have_text('Catalog')

    page.evaluate_script('window.history.forward()')
    find('.landing_main .title').should have_text('Articles')

    page.evaluate_script('window.history.forward()')
    find('.landing_main .title').should have_text('Databases')

  end

end

require 'spec_helper'

describe 'Datasource Sanity', :vcr do

  it "LWeb should be labeled 'Libraries Website'" do
    visit root_path
    expect(find('#datasources')).to have_text('Libraries Website')
  end

  context 'direct datasources links go to landing pages' do

    it 'quicksearch' do
      visit '/quicksearch'
      expect(find('.landing_main .title')).to have_text('Quicksearch')
    end

    it 'catalog' do
      visit '/catalog'
      expect(find('.landing_main .title')).to have_text('Catalog')
    end

    it 'articles' do
      visit '/articles'
      expect(find('.landing_main .title')).to have_text('Articles')
    end

    it 'journals' do
      visit '/journals'
      expect(find('.landing_main .title')).to have_text('E-Journal Titles')
    end

    it 'databases' do
      visit '/databases'
      expect(find('.landing_main .title')).to have_text('Databases')
    end

    it 'ac' do
      visit '/academic_commons'
      expect(find('.landing_main .title')).to have_text('Academic Commons')
    end

    it 'lweb' do
      visit '/library_web'
      expect(find('.landing_main .title')).to have_text('Libraries Website')
    end

    it 'archives' do
      visit '/archives'
      expect(find('.landing_main .title')).to have_text('Archives')
    end

    it 'dissertations' do
      visit '/dissertations'
      expect(find('.landing_main .title')).to have_text('Dissertations')
    end

    it 'ebooks' do
      visit '/ebooks'
      expect(find('.landing_main .title')).to have_text('E-Books')
    end

    it 'newarrivals' do
      visit '/new_arrivals'
      expect(find('.landing_main .title')).to have_text('New Arrivals')
    end

  end

end

describe 'Simple query should retrieve results', :vcr do

  it 'in quicksearch datasource', :js do
    visit quicksearch_index_path(q: 'test')
    expect(page).to have_css('.result_set', count: 4)
    expect(page).to have_css('.nested_result_set', count: 4)
    all('.result_set').each do |result_set|
      expect(result_set).to have_css('.result')
    end
  end

  it 'in catalog datasource' do
    visit catalog_index_path('q' => 'test')
    expect(page).to have_css('.result')
  end

  it 'in articles datasource' do
    visit articles_index_path('q' => 'test')
    expect(page).to have_css('.result')
  end

  it 'in journals datasource' do
    visit journals_index_path('q' => 'test')
    expect(page).to have_css('.result')
  end

  it 'in databases datasource' do
    visit databases_index_path('q' => 'test')
    expect(page).to have_css('.result')
  end

  it 'in ac datasource' do
    visit academic_commons_index_path('q' => 'test')
    expect(page).to have_css('.result')
  end

  it 'in lweb datasource' do
    visit library_web_index_path('q' => 'test')
    expect(page).to have_css('.result')
  end

  it 'in archives datasource' do
    visit archives_index_path('q' => 'test')
    expect(page).to have_css('.result')
  end

  it 'in dissertations datasource', :js do
    visit dissertations_index_path('q' => 'test')
    expect(page).to have_css('.result_set', count: 3)
    expect(page).to have_css('.nested_result_set', count: 3)
    all('.result_set').each do |result_set|
      expect(result_set).to have_css('.result')
    end
  end

  it 'in ebooks datasource', :js do
    visit ebooks_index_path('q' => 'test')
    expect(page).to have_css('.result_set', count: 2)
    expect(page).to have_css('.nested_result_set', count: 2)
    all('.result_set').each do |result_set|
      expect(page).to have_css('.result')
    end
  end

  # Every time we hit new-arrivals, we need to tell the VCR
  # request matcher to ignore 'fq', to get stable cassettes
  it 'in new arrivals datasource', :vcr => {:match_requests_on => [:method, VCR.request_matchers.uri_without_params('facet.query', 'fq')]} do
    visit new_arrivals_index_path('q' => 'test')
    expect(page).to have_css('.result')
  end

end


describe 'Switching between data-source', :vcr do

  # Every time we hit new-arrivals, we need to tell the VCR
  # request matcher to ignore 'fq', to get stable cassettes
  it 'should carry forward simple search to each datasource', :js, :vcr => {:match_requests_on => [:method, VCR.request_matchers.uri_without_params('facet.query', 'fq')]} do
    visit root_path

    # terminal newline submits form
    fill_in 'q', with: "test\n"

    expect(page).to have_css('.result_set', count: 4)
    expect(page).to have_css('.nested_result_set', count: 4)
    all('.result_set').each do |result_set|
      expect(result_set).to have_css('.result')
    end

    within('#datasources') do
      click_link('Catalog')
    end
    expect(find('div.constraint-box')).to have_text('test')
    expect(page).to have_css('.result')
    expect(all('#documents .result').first['source']).to eq 'catalog'

    click_link('Articles')
    expect(find('input#articles_q').value).to eq 'test'
    expect(find('.well-constraints')).to have_text('test')
    expect(page).to have_css('.result')

    click_link('E-Journal Titles')
    expect(find('input#journals_q').value).to eq 'test'
    expect(find('.constraint-box')).to have_text('test')
    expect(page).to have_css('.result')
    expect(all('#documents .result').first['source']).to eq 'catalog'

    click_link('Databases')
    expect(find('input#databases_q').value).to eq 'test'
    expect(find('.constraint-box')).to have_text('test')
    expect(page).to have_css('.result')
    expect(all('#documents .result').first['source']).to eq 'catalog'

    click_link('Academic Commons')
    expect(find('input#academic_commons_q').value).to eq 'test'
    expect(find('.constraint-box')).to have_text('test')
    expect(page).to have_css('.result')
    expect(all('#documents .result').first['source']).to eq 'academic_commons'

    click_link('Libraries Website')
    expect(find('input#library_web_q').value).to eq 'test'
    expect(find('.constraint-box')).to have_text('test')
    expect(page).to have_css('.result')

    click_link('Archives')
    expect(find('input#archives_q').value).to eq 'test'
    expect(find('.constraint-box')).to have_text('test')
    expect(page).to have_css('.result')
    expect(all('#documents .result').first['source']).to eq 'catalog'

    click_link('More...')
    click_link('Dissertations')

    expect(find('input#dissertations_q').value).to eq 'test'

    expect(page).to have_css('.result_set', count: 3)
    expect(page).to have_css('.nested_result_set', count: 3)
# page.save_and_open_screenshot
# page.save_and_open_page
    all('.result_set').each do |result_set|
      expect(result_set).to have_css('.result')
    end

    click_link('E-Books')
    expect(find('input#ebooks_q').value).to eq 'test'
    expect(page).to have_css('.result_set', count: 2)
    expect(page).to have_css('.nested_result_set', count: 2)
    all('.result_set').each do |result_set|
      expect(result_set).to have_css('.result')
    end

    click_link('New Arrivals')
    expect(find('input#new_arrivals_q').value).to eq 'test'
    expect(find('.constraint-box')).to have_text('test')
    expect(page).to have_css('.result')
    expect(all('#documents .result').first['source']).to eq 'catalog'

  end


  # NEXT-978 - "Back" button broken in CLIO
  it 'should allow back/forward navigation', :js do
    visit root_path

    within('#datasources') do
      click_link('Catalog')
    end
    # page.save_and_open_page # debug
    expect(find('.landing_main .title')).to have_text('Catalog')

    within('#datasources') do
      click_link('Articles')
    end
    expect(find('.landing_main .title')).to have_text('Articles')

    within('#datasources') do
      click_link('Databases')
    end
    expect(find('.landing_main .title')).to have_text('Databases')

    page.evaluate_script('window.history.back()')
    expect(find('.landing_main .title')).to have_text('Articles')

    page.evaluate_script('window.history.back()')
    expect(find('.landing_main .title')).to have_text('Catalog')

    page.evaluate_script('window.history.forward()')
    expect(find('.landing_main .title')).to have_text('Articles')

    page.evaluate_script('window.history.forward()')
    expect(find('.landing_main .title')).to have_text('Databases')
  end

end


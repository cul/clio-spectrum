require 'spec_helper'

describe 'Datasource Sanity', :js do

  it "LWeb should be labeled 'Libraries Website'" do
    visit root_path
    expect(find('#datasources')).to have_text('Libraries Website')
  end

  it 'direct datasources links should go to correct datasource landing pages' do

    visit '/quicksearch'
    expect(find('.landing_main .title')).to have_text('Quicksearch')

    visit '/catalog'
    expect(find('.landing_main .title')).to have_text('Catalog')

    visit '/articles'
    expect(find('.landing_main .title')).to have_text('Articles')

    visit '/journals'
    expect(find('.landing_main .title')).to have_text('E-Journal Titles')

    visit '/databases'
    expect(find('.landing_main .title')).to have_text('Databases')

    visit '/academic_commons'
    expect(find('.landing_main .title')).to have_text('Academic Commons')

    visit '/library_web'
    expect(find('.landing_main .title')).to have_text('Libraries Website')

    visit '/archives'
    expect(find('.landing_main .title')).to have_text('Archives')

    visit '/dissertations'
    expect(find('.landing_main .title')).to have_text('Dissertations')

    visit '/ebooks'
    expect(find('.landing_main .title')).to have_text('E-Books')

    visit '/new_arrivals'
    expect(find('.landing_main .title')).to have_text('New Arrivals')

    # visit '/newspapers'
    # expect(find('.landing_main .title')).to have_text('Newspapers')

  end

end

describe 'Simple query should retrieve results ', :js do

  it 'within all datasources' do

    visit quicksearch_index_path('q' => 'test')
    expect(page).to have_css('.result_set', count: 4)
    all('.result_set').each do |result_set|
      expect(result_set).to have_css('.result')
    end

    visit catalog_index_path('q' => 'test')
    expect(page).to have_css('.result')

    visit articles_index_path('q' => 'test')
    expect(page).to have_css('.result')

    visit journals_index_path('q' => 'test')
    expect(page).to have_css('.result')

    visit databases_index_path('q' => 'test')
    expect(page).to have_css('.result')

    visit academic_commons_index_path('q' => 'test')
    expect(page).to have_css('.result')

    visit library_web_index_path('q' => 'test')
    expect(page).to have_css('.result')

    visit archives_index_path('q' => 'test')
    expect(page).to have_css('.result')

    visit dissertations_index_path('q' => 'test')
    expect(page).to have_css('.result_set', count: 3)
    all('.result_set').each do |result_set|
      expect(result_set).to have_css('.result')
    end

    visit ebooks_index_path('q' => 'test')
    expect(page).to have_css('.result_set', count: 2)
    all('.result_set').each do |result_set|
      # expect(result_set).to have_css('.result')
      expect(page).to have_css('.result')
    end

    visit new_arrivals_index_path('q' => 'test')
    expect(page).to have_css('.result')

    # visit newspapers_index_path('q' => 'test')
    # expect(page).to have_css('.result')
  end

end

describe 'Switching between data-source', :js do

  it 'should carry forward simple search to each datasource' do
    visit root_path
    # page.save_and_open_page # debug
    # terminal newline submits form
    fill_in 'q', with: "test\n"

    expect(page).to have_css('.result_set', count: 4)
    all('.result_set').each do |result_set|
      expect(result_set).to have_css('.result')
    end
    # page.save_and_open_page # debug

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
    expect(page).to have_css('.result_count', count: 3)

    all('.result_set').each do |result_set|
      expect(result_set).to have_css('.result')
    end

    click_link('E-Books')
    expect(find('input#ebooks_q').value).to eq 'test'
    expect(page).to have_css('.result_set', count: 2)
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
  it 'should allow back/forward navigation' do
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

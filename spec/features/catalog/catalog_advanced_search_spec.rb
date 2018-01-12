require 'spec_helper'

describe 'Catalog Advanced Search', :vcr do

  it 'should be accessible from the home page' do
    # NEXT-713, NEXT-891 - A Journal Title search should find Newspapers

    # Use this string within the below test
    search_text = 'Japan Times & Mail'

    visit root_path
    within('li.datasource_link[source="catalog"]') do
      click_link('Catalog')
    end
    expect(page).to have_css('#catalog_q')

    find('.search_box.catalog .advanced_search_toggle').click
    expect(page).to have_css('.landing_page.catalog .advanced_search')
    within '.landing_page.catalog .advanced_search' do
      select('Journal Title', from: 'adv_1_field')
      fill_in 'adv_1_value', with: search_text
      find('button[type=submit]').click
    end

    expect(page).to have_css('.constraint-box', text: 'Journal Title: ' + search_text)

    # And the search results too...
    # (struggling to make a regexp work, to do case-insensitive match...)
    # expect(page.body).to match(%r{#{string}}i)
    # page.find 'li.line-item', text: %r{Awesome Line Item}i
    all('.result.document').first.find 'a', text: %r{#{search_text}}i

  end

  # NEXT-705 - "All Fields" should be default, and should be first option
  it "should default to 'All Fields'" do
    visit root_path
    within('li.datasource_link[source="catalog"]') do
      click_link('Catalog')
    end

    find('.search_box.catalog .advanced_search_toggle').click

    expect(find('.landing_page.catalog .advanced_search')).to be_visible

    within '.landing_page.catalog .advanced_search' do

      # For each of our five advanced-search fields...
      (1..5).each do |i|
        select_id = "adv_#{i}_field"

        # The select should exist, and "All Fields" should be selected
        expect(has_select?(select_id, selected: 'All Fields')).to eq true

        # "All Fields" should be the first option in the drop-down select menu
        within("select##{select_id}") do
          expect(first('option').text).to eq 'All Fields'
        end

      end

    end

  end

  # Test each individual advanced-search option
  { 
    'Title' => 'smith',
    'Journal Title' => 'Journal',
    'Author' => 'Smith',
    'Series' => 'Series',
    # We have some funny quoting logic around this field
    'Title Begins With' => '"Three"',
    'Subject' => 'Science',
    'Form/Genre' => 'Manuscript',
    'Publication Place' => 'Boston',
    'Publisher' => 'Penguin',
    'Publication Year' => '1999',
    # check for specific bibs?
    # 'ISBN' => '9780470405543',
    # 'ISSN' => '2372-5699',
    # or search by prefix?
    'ISBN' => '13',
    'ISSN' => '2372',
    'Call Number' => 'PN1995.9.P7',
    'Location' => 'Dakhla Library',
  }.each_pair do |searchField, searchValue|

    it "supports fielded search by #{searchField}", :js do
      visit catalog_index_path

      select searchField, :from => "search_field"
      fill_in 'q', with: searchValue
      find('button[type=submit]').click

      expect(find('.constraint-box')).to have_content("#{searchField}: #{searchValue}")
      expect(page).to have_text "« Previous | 1 - 25 of"
    end


    it "supports advanced search by #{searchField}" do
      visit catalog_index_path

      find('.search_box.catalog .advanced_search_toggle').click
      within '.landing_page.catalog .advanced_search' do
        select(searchField, from: 'adv_1_field')
        fill_in 'adv_1_value', with: searchValue
        find('button[type=submit]').click
      end
      expect(find('.constraint-box')).to have_content("#{searchField}: #{searchValue}")
      expect(page).to have_text "« Previous | 1 - 25 of"
    end


  end

  # NEXT-1113 - location search
  # Specifically, test the ability to search beyond "base" location to 
  # sublocation text.
  [ # Not that many items located at Barnard Reference at the moment.
    # 'Barnard Reference',
    'Lehman Reference',
    # 6/2015 - Barnard library material is being moved about
    # 'Barnard Alumnae Collection',
    'Comp Lit',
    'African Studies',
    'Offsite <Avery>',
    'Offsite <Fine Arts>'
  ].each do |locationSearch|

    it "supports fielded Location search for #{locationSearch}", :js do
      visit catalog_index_path
      # find('btn', text: "All Fields").click
      # within('.search_row') do
      #   find('li', text: 'Location').click
      # end
      select 'Location', :from => "search_field"
      fill_in 'q', with: locationSearch
      find('button[type=submit]').click

      expect(find('.constraint-box')).to have_content("Location: #{locationSearch}")
      expect(page).to have_text "« Previous | 1 - 25 of"
    end


    it "supports advanced Location search for #{locationSearch}" do
      visit catalog_index_path
      find('.search_box.catalog .advanced_search_toggle').click
      within '.landing_page.catalog .advanced_search' do
        select('Location', from: 'adv_1_field')
        fill_in 'adv_1_value', with: locationSearch
        find('button[type=submit]').click
      end
      expect(find('.constraint-box')).to have_content("Location: #{locationSearch}")
      expect(page).to have_text "« Previous | 1 - 25 of"
    end
  end



  # Bug - Dismissing the last advanced-search field should WORK
  # (CatalogController#preprocess_search_params:  undefined method `gsub!' for nil:NilClass)
  it 'should allow dismissing of final advanced fielded search param', :js do
    search_isbn = '978-1-4615-2974-3'

    visit root_path
    within('li.datasource_link[source="catalog"]') do
      click_link('Catalog')
    end

    find('.search_box.catalog .advanced_search_toggle').click

    expect(find('.landing_page.catalog .advanced_search')).to be_visible

    within '.landing_page.catalog .advanced_search' do
      select('ISBN', from: 'adv_1_field')
      fill_in 'adv_1_value', with: search_isbn
      find('button[type=submit]').click
    end

    expect(find('.constraint-box')).to have_content('ISBN: ' + search_isbn)

    within '.constraint-box' do
      find('span.glyphicon.glyphicon-remove').click
    end

    expect(page).to have_css('.result.document')
  end


  # Support advanced/fielded ISBN searches to hit on 020$z, "Canceled/invalid ISBN"
  # NEXT-1050 - Search for invalid ISBN
  # http://www.loc.gov/marc/bibliographic/bd020.html
  it 'should allow advanced ISBN search against "invalid" ISBN' do
    isbn_z = '9789770274208'

    visit root_path
    within('li.datasource_link[source="catalog"]') do
      click_link('Catalog')
    end

    find('.search_box.catalog .advanced_search_toggle').click

    within '.landing_page.catalog .advanced_search' do
      select('ISBN', from: 'adv_5_field')
      fill_in 'adv_5_value', with: isbn_z
      find('button[type=submit]').click
    end

    expect(find('.constraint-box')).to have_content('ISBN: ' + isbn_z)

    title = 'اليوم السابع : الحرب المستحيلة .. حرب الاستنزاف'
    expect(page).to have_text "Title #{title}"
  end

  # NEXT-1050, continued, for basic/fielded search...
  it 'should allow basic fielded ISBN search against "invalid" ISBN', :js do
    isbn_z = '201235125'

    visit catalog_index_path
    # find('btn', text: "All Fields").click
    # within('.search_row') do
    #   find('li', text: "ISBN").click
    # end
    select 'ISBN', :from => "search_field"
    fill_in 'q', with: isbn_z

    # this time, click the little "search" icon
    find('span.glyphicon.glyphicon-search').click

    expect(find('.constraint-box')).to have_content('ISBN: ' + isbn_z)
    expect(page).to have_text "Géographie du Territoire de Belfort".mb_chars.normalize(:d)
  end


end

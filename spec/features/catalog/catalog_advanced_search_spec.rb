require 'spec_helper'

describe 'Catalog Advanced Search' do

  it 'should be accessible from the home page', js: true do
    # NEXT-713, NEXT-891 - A Journal Title search should find Newspapers

    # Use this string within the below test
    search_text = 'Japan Times & Mail'

    visit root_path
    within('li.datasource_link[source="catalog"]') do
      click_link('Catalog')
    end
    find('#catalog_q').should be_visible

    # TODO
    # page.should have_no_selector('.landing_page.catalog .advanced_search')

    find('.search_box.catalog .advanced_search_toggle').click
    find('.landing_page.catalog .advanced_search').should be_visible
    within '.landing_page.catalog .advanced_search' do
      select('Journal Title', from: 'adv_1_field')
      fill_in 'adv_1_value', with: search_text
      find('button[type=submit]').click
    end

    find('.constraint-box').should have_content('Journal Title: ' + search_text)

    # And the search results too...
    # (struggling to make a regexp work, to do case-insensitive match...)
    # page.body.should match(%r{#{string}}i)
    # page.find 'li.line-item', text: %r{Awesome Line Item}i
    # all('.result.document').first.should have_content(search_text)
    # all('.result.document').first.should match(%r{#{search_text}}i)
    all('.result.document').first.find 'a', text: %r{#{search_text}}i

  end

  # NEXT-705 - "All Fields" should be default, and should be first option
  it "should default to 'All Fields'", js: true do
    visit root_path
    within('li.datasource_link[source="catalog"]') do
      click_link('Catalog')
    end

    find('.search_box.catalog .advanced_search_toggle').click

    find('.landing_page.catalog .advanced_search').should be_visible

    within '.landing_page.catalog .advanced_search' do

      # For each of our five advanced-search fields...
      (1..5).each do |i|
        select_id = "adv_#{i}_field"

        # The select should exist, and "All Fields" should be selected
        has_select?(select_id, selected: 'All Fields').should == true

        # "All Fields" should be the first option in the drop-down select menu
        within("select##{select_id}") do
          first('option').text.should == 'All Fields'
        end

      end

    end

  end

  # Bug - Dismissing the last advanced-search field should WORK
  # (CatalogController#preprocess_search_params:  undefined method `gsub!' for nil:NilClass)
  it 'should allow dismissing of final advanced fielded search param', js: true do
    search_isbn = '978-1-4615-2974-3'

    visit root_path
    within('li.datasource_link[source="catalog"]') do
      click_link('Catalog')
    end

    find('.search_box.catalog .advanced_search_toggle').click

    find('.landing_page.catalog .advanced_search').should be_visible

    within '.landing_page.catalog .advanced_search' do
      select('ISBN', from: 'adv_1_field')
      fill_in 'adv_1_value', with: search_isbn
      find('button[type=submit]').click
    end

    find('.constraint-box').should have_content('ISBN: ' + search_isbn)

    within '.constraint-box' do
      find('i.icon-remove').click
    end

    page.should have_css('.result.document')
  end


  # Support advanced/fielded ISBN searches to hit on 020$z, "Canceled/invalid ISBN"
  # NEXT-1050 - Search for invalid ISBN
  # http://www.loc.gov/marc/bibliographic/bd020.html
  it 'should allow advanced ISBN search against "invalid" ISBN', js: true do
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

    find('.constraint-box').should have_content('ISBN: ' + isbn_z)

    title = 'اليوم السابع : الحرب المستحيلة .. حرب الاستنزاف'
    page.should have_text "Title #{title}"
  end

  # NEXT-1050, continued, for basic/fielded search...
  it 'should allow basic fielded ISBN search against "invalid" ISBN', js: true do
    isbn_z = '201235125'

    visit catalog_index_path
    find('btn', text: "All Fields").click
    within('.search_row') do
      find('li', text: "ISBN").click
    end
    fill_in 'q', with: isbn_z

    # this time, click the little "search" icon
    find('i.icon-search').click

    find('.constraint-box').should have_content('ISBN: ' + isbn_z)
    page.should have_text "Géographie du Territoire de Belfort".mb_chars.normalize(:d)
  end


end

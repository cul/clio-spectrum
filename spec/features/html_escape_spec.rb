require 'spec_helper'

describe 'Special HTML characters in MARC data should be escaped' do

  # NEXT-658
  # The Voyager record 6315882 (Auszug aus dem Lager), has
  # HTML embedded in it's 260c ("<font color=red>")
  # This spec validates correct escaping of that HTML.
  # Should cataloging correct that record, this spec will begin to fail,
  # and "red" tests should be removed.
  it 'embedded HTML should not be interpretted' do
  visit catalog_index_path('q' => 'Auszug aus dem Lager zur uberwindung')
  page.should have_css('.result')
  page.should have_css('.result', count: 1)
  page.should have_text('modernen Raumparadigmas')

  # search results list, data comes from SolrDocument
  page.should have_text('<font color=red>')

  # item detail page, data comes from MARC translation
  click_link('Auszug aus dem Lager')

  # this text is only visible on item-detail page
  page.should have_text('Includes bibliographical references')
  page.should have_text('<font color=red>')

  # the quotes should be correctly handled in both the link label and target URL
  page.should have_link('Graduiertenkolleg "Mediale Historiographien."', href: '/catalog?f%5Bauthor_facet%5D%5B%5D=Graduiertenkolleg+%22Mediale+Historiographien.%22')
end

end

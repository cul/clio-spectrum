# encoding: utf-8

require 'spec_helper'

# NEXT-971 - Some WorldCat links to CLIO broken / OCLC-defined 079a not being indexed
describe 'WorldCat link support' do
  it "q of 'ocn213772249' should find Tsukuba Daigaku Tetsugaku Shisōgakukei ronshū" do
    resp = solr_resp_ids_titles_from_query 'ocn213772249'
    resp.should have(1).documents

    # This fails:
    # resp.should include('title_display' => /^Tsukuba Daigaku Tetsugaku Shisōgakukei ronshū$/i)
    # 
    # setup UTF-8 Decomposed form string constants for our various targets
    # (copy & paste gives us the pre-composed, but raw Solr results are decomposed)
    decomposed = 'Tsukuba Daigaku Tetsugaku Shisōgakukei ronshū'.mb_chars.normalize(:d)
    resp.should include('title_display' => /^#{decomposed}$/)
  end
end
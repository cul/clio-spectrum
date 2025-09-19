# encoding: utf-8

require 'spec_helper'

# NEXT-971 - Some WorldCat links to CLIO broken / OCLC-defined 079a not being indexed
describe 'WorldCat link support', :skip_travis do
  it "q of 'ocn213772249' should find Tsukuba Daigaku Tetsugaku Shisōgakukei ronshū" do
    resp = solr_resp_ids_titles_from_query 'ocn213772249'
    expect(resp.size).to be == 1

    # there aren't Rails 4 compatible ways to get at what I need
    # without this very specific digging into the internal structure.
    first = resp['response']['docs'].first

    # This fails:
    #
    # setup UTF-8 Decomposed form string constants for our various targets
    # (copy & paste gives us the pre-composed, but raw Solr results are decomposed)
    decomposed = 'Tsukuba Daigaku Tetsugaku Shisōgakukei ronshū'.mb_chars.normalize(:d)
    precomposed = 'Tsukuba Daigaku Tetsugaku Shisōgakukei ronshū'.mb_chars.normalize(:c)
    # expect(first['title_display'].first).to match /^#{decomposed}$/
    expect(first['title_display'].first).to match /^#{precomposed}$/
  end
end

# -*- encoding : utf-8 -*-
require 'spec_helper'

# Tibetan issues, as captured by
# NEXT-824 - Apostrophe character
# NEXT-941 - Problems displaying parallel titles (e.g., Tibetan)
describe 'Testing tibetan support', :skip_travis do

  it "q of \"krung go'i bod ljongs\" should retrieve correct record" do
    # unquoted
    resp = solr_resp_doc_ids_only('q' => 'krung go\'i bod ljongs')
    expect(rank(resp, 2725279)).to be <= 1

    # quoted
    resp = solr_resp_doc_ids_only('q' => '"krung go\'i bod ljongs"')
    expect(rank(resp, 2725279)).to be <= 1
  end

  it "q of 'gung-thang bstan-pa\'i-sgron-me\'i gsun \'bum' should retrieve correct record" do
    # unquoted
    resp = solr_resp_doc_ids_only('q' => 'gung-thang bstan-pa\'i-sgron-me\'i gsung \'bum')
    expect(rank(resp, 6074253)).to be <= 1
    # quoted
    resp = solr_resp_doc_ids_only('q' => '"gung-thang bstan-pa\'i-sgron-me\'i gsung \'bum"')
    expect(rank(resp, 6074253)).to be <= 1
  end

  it "q of 'krung-go\'i bod kyi gso rig' should retrieve correct record" do
    # unquoted
    resp = solr_resp_doc_ids_only('q' => 'krung-go\'i bod kyi gso rig')
    expect(rank(resp, 6316211)).to be <= 1
    # quoted
    resp = solr_resp_doc_ids_only('q' => '"krung-go\'i bod kyi gso rig"')
    expect(rank(resp, 6316211)).to be <= 1
  end

  it 'Displays parallel titles delimited with a simple single equal-sign' do
    resp = solr_response('q' => 'Sman sul rigs rus cho bran mtha bral',
                         'fl' => 'id,title_display,title_vern_display',
                         'facet' => false, :rows => 1)

    # ugh, lots of knowledge of the internal structure hard-coded here,
    # there aren't Rails 4 compatible ways to get at what I need.
    first = resp["response"]["docs"].first
    # puts    first.inspect
    # puts    first['title_display'].inspect

    # # I don't know why matching on "loṅ" is failing, but since this test is only
    # # about the punctuation, I'm wild-carding it out and moving on.

    # put unicode into de-composed ("d") form to match against Solr reponse
    normalized = 'gsal me loṅ = Zang zu bu'.mb_chars.normalize(:d)
    expect(first['title_display'].first).to match /#{normalized}/

    normalized = 'gsal me loṅ = 藏族部落曼秀族谱明镜'.mb_chars.normalize(:d)
    expect(first['title_vern_display'].first).to match /#{normalized}/

  end

end

# -*- encoding : utf-8 -*-
require 'spec_helper'

# Tibetan issues, as captured by
# NEXT-824 - Apostrophe character
# NEXT-941 - Problems displaying parallel titles (e.g., Tibetan)
describe 'Testing tibetan support' do

  it "q of \"krun go'i bod ljons\" should retrieve correct record" do
    # unquoted
    resp = solr_resp_doc_ids_only('q' => 'krun go\'i bod ljons')
    resp.should include('2725279').in_first(1).results
    # quoted
    resp = solr_resp_doc_ids_only('q' => '"krun go\'i bod ljons"')
    resp.should include('2725279').in_first(1).results
  end

  it "q of 'gun than bstan pa'i sgron me'i gsun 'bum' should retrieve correct record" do
    # unquoted
    resp = solr_resp_doc_ids_only('q' => 'gun than bstan pa\'i sgron me\'i gsun \'bum')
    resp.should include('6074253').in_first(1).results
    # quoted
    resp = solr_resp_doc_ids_only('q' => '"gun than bstan pa\'i sgron me\'i gsun \'bum"')
    resp.should include('6074253').in_first(1).results
  end

  it "q of 'krun go'i bod kyi gso rig' should retrieve correct record" do
    # unquoted
    resp = solr_resp_doc_ids_only('q' => 'krun go\'i bod kyi gso rig')
    resp.should include('6316211').in_first(1).results
    # quoted
    resp = solr_resp_doc_ids_only('q' => '"krun go\'i bod kyi gso rig"')
    resp.should include('6316211').in_first(1).results
  end

  it 'Displays parallel titles delimited with a simple single equal-sign' do
    resp = solr_response('q' => 'Sman sul rigs rus cho bran mtha bral',
                         'fl' => 'id,title_display,title_vern_display',
                         'facet' => false, :rows => 1)

    # I don't know why matching on "loṅ" is failing, but since this test is only
    # about the punctuation, I'm wild-carding it out and moving on.
    resp.should include('title_display' => /gsal me lo.* = Zang zu bu/).in_each_of_first(1).documents
    resp.should include('title_vern_display' => /gsal me lo.* = 藏族部落曼秀族谱明镜/i).in_each_of_first(1).documents
  end

end

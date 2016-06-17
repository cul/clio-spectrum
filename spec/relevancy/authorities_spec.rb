require 'spec_helper'

describe 'Authority support for Author variants' do

  expectedHits = {
    'Ghannouchi'  => 12,
    'Ghanushi'    => 8,
    'Dostoevskii, F M'  => 300,
    'Alicia Chudo'  => 8,
    'Ghaddafi, Muammar' => 15,
    'Khadafy'       => 15,
    'Svetlana Alexievich' => 12,
    'Svetlana Aleksievich'  =>  12,
    'Svetlana Alexievitch'  => 12,
    'Meimares'  =>  4,
    'Μειμαρης, Ιωαννης Εμμ. (Ιωαννης Εμμανουηλ)'  =>  4,
    'Meïmarēs, Giannēs E.'  =>  4,
    'Iōannēs Emmanouēl Meimarēs'  =>  4,
    'Maïmonide, Moïse'  => 300,
    'Qurṭubī, Mūsá ibn Maymūn'  => 300,
    'Organisation de libération palestinienne'  => 3,
    'Irgun le-shiḥrur Palesṭin' => 3,
  }

  expectedHits.each_pair do | term, count |
    it "#{term}" do
      resp = solr_resp_doc_ids_only( author_search_args(term) )
      expect(resp.size).to be >= count
    end
  end

end

describe 'Authority support for Subject variants' do

  expectedHits = {
    'Heart Attack'  => 200,
    'Sarakole Language' =>  4,
    'Fakism'  =>  2,
    'Senior citizens' =>  5000,
  }

  expectedHits.each_pair do | term, count |
    it "#{term}" do
      resp = solr_resp_doc_ids_only( subject_search_args(term) )
      expect(resp.size).to be >= count
    end
  end

end

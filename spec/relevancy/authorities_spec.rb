require 'spec_helper'

# Prepare the Solr index with:
#  bundle exec rake authorities:add_to_bib:by_query['Alexievich']
#  bundle exec rake authorities:add_to_bib:by_query['Dostoyevsky']
#  bundle exec rake authorities:add_to_bib:by_query['Gary Morson']
#  bundle exec rake authorities:add_to_bib:by_query['Ghaddafi']
#  bundle exec rake authorities:add_to_bib:by_query['Qaddafi']
#  bundle exec rake authorities:add_to_bib:by_query['Ghannushi']
#  bundle exec rake authorities:add_to_bib:by_query['Ghannouchi']
#  bundle exec rake authorities:add_to_bib:by_query['ISIS']
#  bundle exec rake authorities:add_to_bib:by_query['Kennedy family']
#  bundle exec rake authorities:add_to_bib:by_query['Maimonides']
#  bundle exec rake authorities:add_to_bib:by_query['Meimaris']
#  bundle exec rake authorities:add_to_bib:by_query['Munaẓẓamat']
#  bundle exec rake authorities:add_to_bib:by_query['Myocardial infarction']
#  bundle exec rake authorities:add_to_bib:by_query['neo-geo']
#  bundle exec rake authorities:add_to_bib:by_query['Older people']
#  bundle exec rake authorities:add_to_bib:by_query['PLO']
#  bundle exec rake authorities:add_to_bib:by_query['Soninke']

describe 'Authority support for Author variants', :skip_travis do
  expectedHits = {
    'Ghannouchi'  => 12,
    'Ghanushi'    => 8,
    'Dostoevskii, F M' => 300,
    'Alicia Chudo' => 8,
    'Ghaddafi, Muammar' => 15,
    'Khadafy' => 15,
    'Svetlana Alexievich' => 12,
    'Svetlana Aleksievich' => 12,
    'Svetlana Alexievitch' => 12,
    'Meimares' => 4,
    'Μειμαρης, Ιωαννης Εμμ. (Ιωαννης Εμμανουηλ)' => 4,
    'Meïmarēs, Giannēs E.' => 4,
    'Maïmonide, Moïse' => 300,
    'Qurṭubī, Mūsá ibn Maymūn' => 300,
    'Organisation de libération palestinienne' => 3,
    'Irgun le-shiḥrur Palesṭin' => 3
  }

  expectedHits.each_pair do |term, count|
    it term.to_s do
      resp = solr_resp_doc_ids_only(author_search_args(term))
      expect(resp.size).to be >= count
    end
  end
end

describe 'Authority support for Subject variants', :skip_travis do
  expectedHits = {
    'Heart Attack' => 150,
    'Sarakole Language' => 4,
    'Fakism' => 2,
    'Senior citizens' => 5000
  }

  expectedHits.each_pair do |term, count|
    it term.to_s do
      resp = solr_resp_doc_ids_only(subject_search_args(term))
      expect(resp.size).to be >= count
    end
  end
end

describe 'Authority support for Author authorities used as Subjects', :skip_travis do
  expectedHits = {
    'Gaddafi' => 1,
    'Keneday family' => 1,
    'Palestine Liberation Organization' => 1,
    # 'COP21' =>  1,
    'Kyiv' =>  1
  }

  expectedHits.each_pair do |term, count|
    it term.to_s do
      resp = solr_resp_doc_ids_only(subject_search_args(term))
      expect(resp.size).to be >= count
    end
  end
end

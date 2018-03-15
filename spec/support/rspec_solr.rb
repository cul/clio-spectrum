# encoding: utf-8

# All below originally copied from the spec_helper of:
#   https://github.com/sul-dlss/sw_index_tests
# and modified for Columbia context

require 'yaml'
require 'rsolr'

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec-solr'

# Not yet
# require 'support/shared_examples_cjk'

RSpec.configure do |config|
  # baseurl = ENV["URL"]
  # if baseurl
  #   solr_config = {:url => baseurl}
  # else
  #   yml_group = ENV["YML_GROUP"] ||= 'test'
  #   solr_config = YAML::load_file('config/blacklight.yml')[yml_group]
  # end

  solr_url = SOLR_CONFIG['test']['url']
  connection_config = { url: solr_url }

  SOLR = RSolr.connect(connection_config)
end


# Quick function to make simpler syntax in specs
def rank(resp, bib)
  position = resp.get_first_doc_index(bib.to_s)
  # not-found, pretend it's just really, really low ranking
  return 999999 if position.nil?
  return position +1
end

# send a GET request to the default Solr request handler with the indicated query
# @param query [String] the value of the 'q' param to be sent to Solr
# @return [RSpecSolr::SolrResponseHash] object for rspec-solr testing the Solr response, with no facets, and only the id field for each Solr doc
def solr_resp_ids_from_query(query)
  resp = solr_resp_doc_ids_only('q' => query)
end

def solr_resp_ids_from_journal_title_query(query)
  solr_resp_doc_ids_only('q'  => "{!qf=$title_qf pf=$title_pf}#{query}",
                         'fq' => 'format:Journal/Periodical',
                         'sort' => 'score desc, pub_date_sort desc')
end

# send a GET request to the default Solr request handler with the indicated query
# @param query [String] the value of the 'q' param to be sent to Solr
# @return [RSpecSolr::SolrResponseHash] object for rspec-solr testing the Solr response, with no facets, and only the id and title_245a_display field for each Solr doc
def solr_resp_ids_titles_from_query(query)
  resp = solr_resp_ids_titles('q' => query)
end

# send a GET request to the default Solr request handler with the indicated query
# @param query [String] the value of the 'q' param to be sent to Solr
# @return [RSpecSolr::SolrResponseHash] object for rspec-solr testing the Solr response, with no facets, and only the id and title_full_display field for each Solr doc
def solr_resp_ids_full_titles_from_query(query)
  resp = solr_resp_ids_full_titles('q' => query)
end

# send a GET request to the default Solr request handler with the indicated Solr parameters
# @param solr_params [Hash] the key/value pairs to be sent to Solr as HTTP parameters, in addition to
#  those to get only id fields and no facets in the response
# @return [RSpecSolr::SolrResponseHash] object for rspec-solr testing the Solr response, with no facets, and only the id field for each Solr doc
def solr_resp_doc_ids_only(solr_params)
  solr_response(solr_params.merge(doc_ids_only))
end

def solr_resp_ejournal_ids_only(solr_params)
  solr_response(solr_params.merge(doc_ids_only).merge(ejournal_titles))
end

# send a GET request to the default Solr request handler with the indicated Solr parameters
# @param solr_params [Hash] the key/value pairs to be sent to Solr as HTTP parameters, in addition to
#  those to get only id fields and title_245a_display and no facets in the response
# @return [RSpecSolr::SolrResponseHash] object for rspec-solr testing the Solr response, with no facets, and only the id and short title field for each Solr doc
def solr_resp_ids_titles(solr_params)
  solr_response(solr_params.merge(doc_ids_short_titles))
end

# send a GET request to the default Solr request handler with the indicated Solr parameters
# @param solr_params [Hash] the key/value pairs to be sent to Solr as HTTP parameters, in addition to
#  those to get only id fields and title_full_display and no facets in the response
# @return [RSpecSolr::SolrResponseHash] object for rspec-solr testing the Solr response, with no facets, and only the id and full title field for each Solr doc
def solr_resp_ids_full_titles(solr_params)
  solr_response(solr_params.merge(doc_ids_full_titles))
end

# def author_search_args(query_str)
#   { 'q' => "{!qf=$author_qf pf=$pf_author pf3=$pf3_author pf2=$pf2_author}#{query_str}", 'qt' => 'search' }
# end
def author_search_args(query_str)
  { 'q' => "{!qf=$author_qf pf=$pf_author}#{query_str}"}
end

def title_search_args(query_str)
  { 'q' => "{!qf=$title_qf pf=$pf_title pf3=$pf3_title pf2=$pf2_title}#{query_str}", 'qt' => 'search' }
end

# fixed for CLIO
def subject_search_args(query_str)
  { 'q' => "{!qf=$subject_qf pf=$subject_pf}#{query_str}"}
end

def series_search_args(query_str)
  { 'q' => "{!qf=$qf_series pf=$pf_series pf3=$pf3_series pf2=$pf2_series}#{query_str}", 'qt' => 'search' }
end

def callnum_search_args(query_str)
  { 'q' => "#{query_str}", 'defType' => 'lucene', 'df' => 'callnum_search', 'qt' => 'search' }
end

def author_title_search_args(query_str)
  { 'q' => "{!qf=author_title_search pf='author_title_search^10' pf3='author_title_search^5' pf2='author_title_search^2'}#{query_str}", 'qt' => 'search' }
end

# def cjk_everything_q_arg(query_str)
#   "{!qf=$qf_cjk pf=$pf_cjk pf3=$pf3_cjk pf2=$pf2_cjk}#{query_str}"
# end
# 
# def cjk_author_q_arg(query_str)
#   "{!qf=$author_qf_cjk pf=$pf_author_cjk pf3=$pf3_author_cjk pf2=$pf2_author_cjk}#{query_str}"
# end
# 
# def cjk_title_q_arg(query_str)
#   "{!qf=$title_qf_cjk pf=$pf_title_cjk pf3=$pf3_title_cjk pf2=$pf2_title_cjk}#{query_str}"
# end
# 
# def cjk_subject_q_arg(query_str)
#   "{!qf=$subject_qf_cjk pf=$pf_subject_cjk pf3=$pf3_subject_cjk pf2=$pf2_subject_cjk}#{query_str}"
# end

# def cjk_series_q_arg(query_str)
#   "{!qf=$qf_series_cjk pf=$pf_series_cjk pf3=$pf3_series_cjk pf2=$pf2_series_cjk}#{query_str}"
# end
# 
# return the number of CJK unigrams in the str
def num_cjk_uni(str)
  if str
    str.scan(/\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/).size
  else
    0
  end
end

# # if there are any CJK chars in str, return the number of CJK bigrams + CJK unigrams + non-CJK words in the str
# # if there are no CJK chars in str, return nil
# def cjk_bigram_tokens(str)
#   num_uni = num_cjk_uni(str)
#   if num_uni.nonzero?
#     num_bi = 0
#     (0..str.length - 2).each do |i|
#       num_bi += 1 if str[i, 2].match(/(\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}){2}/)
#     end
#     num_non_cjk_tokens = str.scan(/[[:alnum]]+/).size
#     num_uni + num_bi + num_non_cjk_tokens
#   else
#     nil
#   end
# end
# 
# # the Solr mm value if it is to be adjusted due to CJK chars in the query string
# @cjk_mm_val = '3<86%'
# def cjk_mm_val
#   @cjk_mm_val
# end

# # return a hash containing mm and qs Solr parameters based on the CJK characters in the str
# def cjk_mm_qs_params(str)
#   num_uni = num_cjk_uni(str)
#   if num_uni > 2
#     num_non_cjk_tokens = str.scan(/[[:alnum]]+/).size
#     if num_non_cjk_tokens > 0
#       lower_limit = cjk_mm_val[0].to_i
#       mm = (lower_limit + num_non_cjk_tokens).to_s + cjk_mm_val[1, cjk_mm_val.size]
#       { 'mm' => mm, 'qs' => 0 }
#     else
#       { 'mm' => @cjk_mm_val, 'qs' => 0 }
#     end
#   else
#     {}
#   end
# end
# 
# # @param query_type [String] the type of query:  title, author, ...
# # @param query [String] the query string to be used against cjk-expecting qf, pf, pf3, pf2 args
# # @param solr_params [Hash<String>,<String>] any additional parameters to send to Solr
# # @return [RSpecSolr::SolrResponseHash] object based on the query type and the query
# def cjk_query_resp_ids(query_type, query, solr_params = {})
#   resp = solr_resp_doc_ids_only({ 'q' => cjk_q_arg(query_type, query) }.merge(solr_params))
# end

# # @param query_type [String] the type of query:  title, author, ...
# # @param query [String] the query string to be used against cjk-expecting qf, pf, pf3, pf2 args
# # @return [String] the value of the q arg (including all Solr local params) for a CJK query, based on the query_type
# def cjk_q_arg(query_type, query)
#   case query_type
#     when 'author'
#       cjk_author_q_arg(query)
#     when 'subject'
#       cjk_subject_q_arg(query)
#     when 'series'
#       cjk_series_q_arg(query)
#     when 'title'
#       cjk_title_q_arg(query)
#     else
#       cjk_everything_q_arg(query)
#   end
# end

# private

# send a GET request to the indicated Solr request handler with the indicated Solr parameters
# @param solr_params [Hash] the key/value pairs to be sent to Solr as HTTP parameters
# @param req_handler [String] the pathname of the desired Solr request handler (defaults to 'select')
# @return [RSpecSolr::SolrResponseHash] object for rspec-solr testing the Solr response
def solr_response(solr_params, req_handler = 'select')
  q_val = solr_params['q']
  if num_cjk_uni(q_val) == 0
    RSpecSolr::SolrResponseHash.new(SOLR.send_and_receive(req_handler, method: :get, params: solr_params.merge('testing' => 'clio_index_test')))
  else
    # we have CJK - separate user query string out from local params
    if q_val =~ /\{(.*)\}(.*)/
      qf_pf_args = Regexp.last_match[1]
      q_val = Regexp.last_match[2]
      # use CJK local params
      if qf_pf_args && q_val
        case qf_pf_args
          when /author_qf/
            solr_params['q'] = cjk_author_q_arg q_val
          when /title_qf/
            solr_params['q'] = cjk_title_q_arg q_val
          when /subject_qf/
            solr_params['q'] = cjk_subject_q_arg q_val
          when /qf_series/
            solr_params['q'] = cjk_series_q_arg q_val
        end
      end
    else
      solr_params['q'] = cjk_everything_q_arg q_val
    end
    RSpecSolr::SolrResponseHash.new(SOLR.send_and_receive(req_handler, method: :get,
                                                                       params: solr_params.merge('testing' => 'clio_index_test').merge(cjk_mm_qs_params(q_val))))
  end # have CJK in query
end

# use these Solr HTTP params to reduce the size of the Solr responses
# response documents will only have id fields, and there will be no facets in the response
DOC_IDS_ONLY = { 'fl' => 'id', 'facet' => 'false', 'rows' => '200' }
DOC_IDS_TITLES = { 'fl' => 'id,title_display', 'facet' => 'false', 'rows' => '50' }
# DOC_IDS_FULL_TITLES = {'fl'=>'id,title_full_display', 'facet'=>'false'}

# response documents will only have id fields, and there will be no facets in the response
# @return [Hash] Solr HTTP params to reduce the size of the Solr responses
def doc_ids_only
  DOC_IDS_ONLY
end

# Columbia doesn't have "short" and "full" titles.  Both calls return the same thing.
def doc_ids_short_titles
  DOC_IDS_TITLES
end

def doc_ids_full_titles
  DOC_IDS_TITLES
end

def ejournal_titles
  # return the filter-query param, to be merged into the Solr search:
  { 'fq' => '{!raw f=source_facet}ejournal' }
end

# # response documents will only have id and title_245a_display fields, and there will be no facets in the response
# # @return [Hash] Solr HTTP params to reduce the size of the Solr responses
# def doc_ids_short_titles
#   DOC_IDS_SHORT_TITLES
# end
#
# # response documents will only have id and title_full_display fields, and there will be no facets in the response
# # @return [Hash] Solr HTTP params to reduce the size of the Solr responses
# def doc_ids_full_titles
#   DOC_IDS_FULL_TITLES
# end

# marquis - I think we don't need these???

# def solr_conn
#   SOLR
# end
# 
# def solr_schema
#   @schema_xml ||= SOLR.send_and_receive('admin/file/', method: :get, params: { 'file' => 'schema.xml', :wt => 'xml' })
# end
# 
# def solr_config_xml
#   @solrconfig_xml = SOLR.send_and_receive('admin/file/', method: :get, params: { 'file' => 'solrconfig.xml', :wt => 'xml' })
# end

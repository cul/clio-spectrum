module SavedListsHelper


def get_full_url(list)
  root_path(:only_path => false).sub(/\/$/, '') + list.url
  # url = lists_path(:only_path => false) + "/" + current_user.login
  # url += "/#{list.slug}" unless list.is_default?
  # url
end

# Use model's get_display_name() instead
# def get_list_name(list)
#   return "My List" if list.is_default?
#   return list.name
# end


def get_permissions_label(permissions)
  case permissions
    when "private"
      html = "<span class='label label-info'>private</span>"
    when "public"
      html = "<span class='label label-warning'>public</span>"
    else
      raise "get_permissions_label: unexpected value: #{permission}"
    end
    html.html_safe
end


# def get_summon_docs_for_id_values(id_array)
#
#   @params = {
#     'spellcheck' => true,
#     's.ho' => true,
#     # 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article)',
#     # 's.ff' => ['ContentType,and,1,5', 'SubjectTerms,and,1,10', 'Language,and,1,5']
#   }
#
#   @config = APP_CONFIG['summon']
#   @config.merge!(:url => 'http://api.summon.serialssolutions.com/2.0.0')
#   @config.symbolize_keys!
#
#
#   @params['s.cmd'] ||= "setFetchIDs(#{id_array.join(',')})"
#
#
#   @params['s.q'] ||= ''
#   @params['s.fq'] ||= ''
#   @params['s.role'] ||= ''
#
#   @errors = nil
#   begin
#     @service = ::Summon::Service.new(@config)
#
#     Rails.logger.info "[Spectrum][Summon] config: #{@config}"
#     Rails.logger.info "[Spectrum][Summon] params: #{@params}"
#
#     ### THIS is the actual call to the Summon service to do the search
#     @search = @service.search(@params)
#
#   rescue Exception => e
#     Rails.logger.error "[Spectrum][Summon] error: #{e.message}"
#     @errors = e.message
#   end
#
#   # we choose to return empty list instead of nil
#   @search ? @search.documents : []
# end

# # given a field name and array of values, get the matching SOLR documents
# def get_solr_response_for_field_values(field, values, extra_solr_params = {})
#   values ||= []
#   values = [values] unless values.respond_to? :each
#
#   q = nil
#   if values.empty?
#     q = "NOT *:*"
#   else
#     q = "#{field}:(#{ values.to_a.map { |x| solr_param_quote(x)}.join(" OR ")})"
#   end
#
#   solr_params = {
#     :defType => "lucene",   # need boolean for OR
#     :q => q,
#     # not sure why fl * is neccesary, why isn't default solr_search_params
#     # sufficient, like it is for any other search results solr request?
#     # But tests fail without this. I think because some functionality requires
#     # this to actually get solr_doc_params, not solr_search_params. Confused
#     # semantics again.
#     :fl => "*",
#     :facet => 'false',
#     :spellcheck => 'false'
#   }.merge(extra_solr_params)
#
#   solr_response = find(blacklight_config.qt, self.solr_search_params().merge(solr_params) )
#   document_list = solr_response.docs.collect{|doc| SolrDocument.new(doc, solr_response) }
#   [solr_response,document_list]
# end


end

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def application_name
    APP_CONFIG['application_name'].to_s
  end

  def alternating_line(id="default")
    @alternating_line ||= Hash.new("odd")
    @alternating_line[id] = @alternating_line[id] == "even" ? "odd" : "even"
  end


  def alternating_bit(id="default")
    @alternating_bits ||= Hash.new(1)
    @alternating_bits[id] = 1 - @alternating_bits[id]
  end

  def auto_add_empty_spaces(text)
    text.to_s.gsub(/([^\s-]{5})([^\s-]{5})/,'\1&#x200B;\2')
  end

  # determines if the given document id is in the folder
  def item_in_folder?(doc_id)
    session[:folder_document_ids] && session[:folder_document_ids].include?(doc_id.listify.first) ? true : false
  end

  def determine_search_params
    if params['action'] = 'show'
      return session['search'] || {}
    else
      return params
    end
  end

  # Copy functionality of BlackLight's sidebar_items, 
  # new deprecated, over to CLIO-specific version
  # collection of items to be rendered in the @sidebar
  def clio_sidebar_items
    @clio_sidebar_items ||= []
  end


  # def ids_to_documents(id_array = [])
  #   # First, split into per-source lists,
  #   # (depend on Summon IDs to start with "FETCH"...)
  #   catalog_item_ids = []
  #   articles_item_ids = []
  #   Array.wrap(id_array).each do |item_id|
  #     if item_id.start_with?("FETCH")
  #       articles_item_ids.push item_id
  #     else
  #       catalog_item_ids.push item_id
  #     end
  #   end
  #
  #   # Then, do two source-specific set-of-id lookups
  #   response, catalog_document_list = get_solr_response_for_field_values(SolrDocument.unique_key, catalog_item_ids)
  #   article_document_list = get_summon_docs_for_id_values(articles_item_ids)
  #
  #   # Then, merge back, in original order
  #   key_to_doc_hash = {}
  #   catalog_document_list.each do |doc|
  #     puts "======CATALOG DOC=====\n#{doc}\n==========="
  #     key_to_doc_hash[ doc[:id] ] = doc
  #   end
  #   article_document_list.each do |doc|
  #     puts "======ARTICLE DOC=====\n#{doc}\n==========="
  #     key_to_doc_hash[ doc.id ] = doc
  #   end
  #   puts "=======KEYS========= #{key_to_doc_hash.keys}"
  #
  #   document_array = []
  #   id_array.each do |id|
  #     document_array.push key_to_doc_hash[id]
  #   end
  #   document_array
  # end

end

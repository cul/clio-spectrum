# Call Number Browse
# 
# Based on Stanford SearchWorks
# 

class BrowseController < ApplicationController
  include Blacklight::Catalog::SearchContext
  include Blacklight::Configurable
  include Blacklight::SolrHelper

  include LocalSolrHelperExtension

  include BlacklightRangeLimit::ControllerOverride


  helper_method :get_call_number, :get_shelfkey, :get_reverse_shelfkey



  # include Thumbnail
  copy_blacklight_config_from(CatalogController)

  def index
    return unless params[:start].present?

    @response, @original_doc = get_solr_response_for_doc_id(params[:start])
    barcode = params[:barcode] || @original_doc[:preferred_barcode]

    respond_to do |format|
      format.html do
        @document_list = NearbyOnShelf.new(
          "static",
          blacklight_config,
          {:item_display => @original_doc[:item_display],
           :preferred_barcode=>barcode,
           :before => 9,
           :after => 10,
           :page => params[:page]}
        ).items.map do |document|
          SolrDocument.new(document[:doc])
        end
      end
    end

  end


  #### Name our XHR handler "_mini" and our HTML handler "_full", so that
  #### they have different URLs, so they cache distinctly in client browsers.
  def shelfkey_mini
    return unless request.xhr?
    return unless params[:shelfkey].present?
    # all shelfkeys in Solr are normalized to lower-case
    @shelfkey = params[:shelfkey].downcase

    before_count = params[:before] || 4
    after_count  = params[:after] || 5

    # A Browse-Item is a hash reflecting a doc with it's currently 
    # activated position within the browse context:
    # {
    #   doc:  SolrDocument,
    #   active_call_number:
    #   active_shelfkey:
    #   active_reverse_shelfkey:
    # }
    @browse_item_list = shelfkey_to_item_list(@shelfkey, before_count, after_count)

    render 'shelfkey', layout: false
  end


  def shelfkey_full
    return if request.xhr?
    return unless params[:shelfkey].present?

    # all shelfkeys in Solr are normalized to lower-case
    @shelfkey = params[:shelfkey].downcase

    before_count = params[:before] || 3
    after_count  = params[:after] || 16

    # A Browse-Item is a hash reflecting a doc with it's currently 
    # activated position within the browse context:
    # {
    #   doc:  SolrDocument,
    #   active_call_number:
    #   active_shelfkey:
    #   active_reverse_shelfkey:
    # }
    @browse_item_list = shelfkey_to_item_list(@shelfkey, before_count, after_count)

    render 'shelfkey', layout: 'quicksearch'
  end


  def shelfkey_to_item_list(shelfkey, before_count, after_count)
    forward_items = get_items_by_shelfkey_forward(shelfkey, after_count)

    # pull off the current item
    this_item = forward_items.shift

    # For "Before" query, we need the reverse shelfkey.
    reverse_shelfkey = shelfkey_to_reverse_shelfkey(this_item, shelfkey)
    backward_items = get_items_by_reverse_shelfkey_backward(reverse_shelfkey, before_count)

    # pull off the current  item
    backward_items.shift
# raise
    ordered_item_list = backward_items.reverse + [this_item] + forward_items

    return ordered_item_list
  end


  def get_items_by_shelfkey_forward(shelfkey, after_count)
    return get_items_by_key("shelfkey", shelfkey, after_count)
  end


  def get_items_by_reverse_shelfkey_backward(reverse_shelfkey, before_count)
    return get_items_by_key("reverse_shelfkey", reverse_shelfkey, before_count)
  end


  # def get_items_by_shelfkey_forward(shelfkey, after_count)
  def get_items_by_key(fieldname, fieldvalue, count)
    # lookup self plus "count" records onwards
    total_count = 1 + count
    # Fetch OVER the number required... because
    # if doc[123] occupies positions N and N+1 in the returned list, 
    # those multiple appearances will collapse into a single Doc in
    # the browse-item-list, which means you'll fall short of how many
    # uniq docs you want back.  
    # Add, arbitrarily, 5 extra.  Could be 10, could be x2, whatever.
    fetch_count = total_count + 5

    # Get the _ordered_ list of keys (using Solr term query)
    key_list = get_next_terms(fieldvalue, fieldname, fetch_count)

    # Get the unordered set of Solr docs
    # Fetch OVER the number required... because
    # if doc[123] occupies positions N and N+1 in the returned list, 
    # those multiple appearances will collapse into a single Doc in
    # the browse-item-list, which means you'll fall short of how many
    # uniq docs you want back.
    solr_params = {rows: fetch_count}
    response, solr_document_list = get_solr_response_for_field_values(fieldname, key_list, solr_params)

    # Pair up the ordered shelfkeys with matching documents.
    # Potentially messy...
    # shelfkeys [L,M,N,O]
    # docs[1][shelfkeys]=[L]
    # docs[2][shelfkeys]=[A,M]
    # docs[3][shelfkeys]=[M,Z]
    # docs[4][shelfkeys]=[M,N]
    # docs[5][shelfkeys]=[O]
    # map = {L => [ docs[1] ], M => [ docs[2],docs[3] ], N => [docs[4]]}


    item_hash_list = solr_document_list.map{ |doc|
      # which key does this doc match?
      key = key_list.select { |this_key|
        doc[fieldname].any? { |doc_key|
          doc_key.downcase == this_key.downcase
        }
      }.first

      # return the item-hash of this doc with the key used to select it...
      { doc: doc, key: key}

    }

    # Sort our retrieved docs by their key
    item_hash_list.sort!{ |x,y|
      x[:key] <=> y[:key]
    }

    # Use the key to fetch the matching item_display jumbo field,
    # parse it out into separate fields
    item_hash_list.each { |item|
      # raise
      item[:current_call_number] = get_call_number(get_item_display(item, item[:key]) )
      item[:current_shelfkey] = get_shelfkey(get_item_display(item, item[:key]) )
      item[:current_reverse_shelfkey] = get_reverse_shelfkey(get_item_display(item, item[:key]) )
    }

# raise

    # return only the correct number of items
    # (duplicate shelfkeys could have bumped up document count)
    return item_hash_list[0..count]
  end



  def get_next_terms(curr_value, field, how_many)
    # TermsComponent Query to get the terms
    solr_params = {
      'terms.fl' => field,
      'terms.lower' => curr_value,
      'terms.sort' => 'index',
      'terms.limit' => how_many
    }
    solr_response = Blacklight.solr.alphaTerms({params: solr_params})
    # create array of one element hashes with key=term and value=count
    result = []
    terms ||= solr_response['terms'] || []
    if terms.is_a?(Array)
      field_terms ||= terms[1] || []  # solr 1.4 returns array
    else
      field_terms ||= terms[field] || []  # solr 3.5 returns hash
    end
    # field_terms is an array of value, then num hits, then next value, then hits ...
    i = 0
    until result.length == how_many || i >= field_terms.length do
      # marquis - do we need to know count of hits per term at this point?
      # term_hash = {field_terms[i] => field_terms[i+1]}
      # result << term_hash
      # marquis - let's try simple array of values:
      result << field_terms[i]
      i = i + 2
    end

    result
  end




  def shelfkey_to_reverse_shelfkey(item, shelfkey)
    # fetch the correct item_display jumbo field
    item_display_field = get_item_display(item, shelfkey)

    # dig out the correct sub-component of the jumbo field
    return get_reverse_shelfkey(item_display_field)
  end


  # given a document and the barcode of an item in the document, return the
  #  item_display field corresponding to the barcode, or nil if there is no
  #  such item
  def get_item_display(item, key)
    # raise
    item_display = item[:doc][:item_display]
    match = ""
    if key.nil? || key.length == 0
      return nil
    end
    [item_display].flatten.each do |item_disp|
      return item_disp if item_disp.downcase.include? key.downcase
      # raise
      # match = item_disp if item_disp =~ /#{CGI::escape(key)}/i
      # # marquis - add this match...
      # match = item_disp if item_disp =~ /#{key}/i
    end
    return match unless match == ""
  end


  # return the call-number piece of the item_display field
  def get_call_number(item_display)
    get_item_display_piece(item_display, 0)
  end


  # return the shelfkey piece of the item_display field
  def get_shelfkey(item_display)
    # get_item_display_piece(item_display, 6)
    get_item_display_piece(item_display, 1)
  end


  # return the reverse shelfkey piece of the item_display field
  def get_reverse_shelfkey(item_display)
    # get_item_display_piece(item_display, 7)
    get_item_display_piece(item_display, 2)
  end


  def get_item_display_piece(item_display, index)
    if (item_display)
      # item_array = item_display.split('-|-')
      item_array = item_display.split(' | ')

      return item_array[index].strip unless item_array[index].nil?
    end
    nil
  end




  def nearby_SearchWorks
    return unless params[:start].present?

    @response, @document = get_solr_response_for_doc_id(params[:start])

# raise
    # barcode = params[:barcode] || @original_doc[:preferred_barcode]
    barcode = params[:barcode] || @document[:call_number_txt].first

    respond_to do |format|
      format.html do
        nearby = NearbyOnShelf.new(
          "static",
          blacklight_config,
          {:item_display => @document[:item_display],
           :preferred_barcode=>barcode,
           :before => 12,
           :after => 12}
        )
        # ).items.map do |document|
        #   SolrDocument.new(document[:doc])
        # end
        raise
        # render :browse, locals: {document: @document, nearby_list: @nearby_list}, layout:false
        render  locals: {document: @document, nearby_list: nearby.items}, layout:false
      end
    end
  end

  private

# ???
  # def _prefixes
  #   @_prefixes ||= super + ['catalog']
  # end

end

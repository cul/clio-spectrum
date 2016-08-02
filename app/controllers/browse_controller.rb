# Call Number Browse
# 
# Based on Stanford SearchWorks
# 

class BrowseController < ApplicationController
  include Blacklight::SearchContext
  include Blacklight::Configurable
  include Blacklight::SearchHelper

  include LocalSolrHelperExtension

  include BrowseSupport

  copy_blacklight_config_from(CatalogController)

  #### Name our XHR handler "_mini" and our HTML handler "_full", so that
  #### they have different URLs, so they cache distinctly in client browsers.

  def shelfkey_mini
    render nothing: true and return unless request.xhr?

    shelfkey_browse('mini')
  end

  def shelfkey_full
    render nothing: true and return if request.xhr?

    shelfkey_browse('full')
  end

  def shelfkey_browse(mini_or_full)
  # def shelfkey_browse
    render nothing: true and return unless params[:shelfkey].present?

    # We'll use Session for storing state about our browse session
    session[:browse] = {} unless session[:browse].is_a?(Hash)

    default_before_items = 2
    # if (mini_or_full == 'full')
    # Try basing this on....
    if request.xhr?
      # How many items to show for mini-browse?
      session[:browse]['per_page'] = 10
    else
      session[:browse]['per_page'] = get_browser_option('catalog_per_page') || 25
    end

    before_count = (params[:before] || default_before_items).to_i

    # Total, minus current item, minus what comes before, equals what's after
    default_after_items = (session[:browse]['per_page']).to_i - before_count - 1
    after_count  = (params[:after] || default_after_items).to_i

    # all shelfkeys in Solr are normalized to lower-case
    @shelfkey = params[:shelfkey].downcase

    # Which bib id to highlight
    if params[:bib]
      response, document = fetch(params[:bib])

      # Record the starting item for browsing in the Session
      # This will not be part of URL (i.e., won't survive 
      # bookmarking, emailing, etc.)
      session[:browse]['bib'] = document.id
      # Need the Call Number corresponding to the active shelfkey
      active_item_display = get_item_display(document, @shelfkey)
      session[:browse]['call_number'] = get_call_number(active_item_display)
      session[:browse]['shelfkey'] = get_shelfkey(active_item_display)
    end



    # A Browse-Item is a hash reflecting a doc with it's currently 
    # activated position within the browse context:
    # {
    #   doc:  SolrDocument,
    #   active_call_number:
    #   active_shelfkey:
    #   active_reverse_shelfkey:
    # }
    @browse_item_list = shelfkey_to_item_list(@shelfkey, before_count, after_count)

    # If the lookup by shelfkey failed, display nothing
    if @browse_item_list.nil? || (@browse_item_list.size == 0)
      render nothing: true and return
    end

    # if mini_or_full == 'mini'
    # Try basing this on....
    if request.xhr?
      render layout: false
    else
      render layout: 'quicksearch'
    end
  end



  def shelfkey_to_item_list(shelfkey, before_count, after_count)
    # raise
    forward_items = get_items_by_shelfkey_forward(shelfkey, after_count)
    return nil if forward_items.nil? || forward_items.size == 0

    # pull off the current item
    this_item = forward_items.shift

    # For "Before" query, we need the reverse shelfkey.
    # (Sometimes due to data issues, the current 'shelfkey' variable will not
    #  exactly match the first item in forward_items.  Go with first item.)

    # This fishing is unnecessary.  The call to get_items_by_shelfkey_forward()
    # already figured out the reverse key.
    # reverse_shelfkey = shelfkey_to_reverse_shelfkey(this_item, shelfkey)
    reverse_shelfkey = this_item[:current_reverse_shelfkey]
    return nil if reverse_shelfkey.nil?

    backward_items = get_items_by_reverse_shelfkey_backward(reverse_shelfkey, before_count) || []

    # pull off the current item
    # backward_items.shift
    # raise
    # there may be multiple items sharing the shelfkey - delete them all...
    backward_items.delete_if { |item|
      item[:key] == reverse_shelfkey
    }
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


  def get_items_by_key(fieldname, fieldvalue, count)
    Rails.logger.debug "get_items_by_key(#{fieldname}, #{fieldvalue}, #{count})"

    # Fetch OVER the number required... because
    # if doc[123] occupies positions N and N+1 in the returned list, 
    # those multiple appearances will collapse into a single Doc in
    # the browse-item-list, which means you'll fall short of how many
    # uniq docs you want back.  
    # Add, arbitrarily, 5 extra.  Could be 10, could be x2, whatever.
    fetch_term_count = count + 10
    fetch_doc_count = fetch_term_count + 10

    # Get the _ordered_ list of keys (using Solr term query)
    key_list = get_next_terms(fieldvalue, fieldname, fetch_term_count)
    # We must fetch a list of items
    return [] if key_list.nil? || key_list.size == 0
    # One of the items must be the original lookup key
    return [] unless key_list.include? fieldvalue

    key_list.each { |key|
      Rails.logger.debug "key=#{key.inspect} #{' ==> MATCH' if key == fieldvalue}"
    }

    # Get the unordered set of Solr docs
    # Fetch OVER the number required... because
    # if doc[123] occupies positions N and N+1 in the returned list, 
    # those multiple appearances will collapse into a single Doc in
    # the browse-item-list, which means you'll fall short of how many
    # uniq docs you want back.
    solr_params = {rows: fetch_doc_count}

    # This fails when page-size is large, 50 or so.
    # Run the query in slices, merge them.
    solr_document_list = []
    key_list.each_slice(20) { |slice|
      # response, slice_document_list = get_solr_response_for_field_values(fieldname, slice, solr_params)
      response, slice_document_list = fetch(slice, solr_params)
      solr_document_list += slice_document_list
    }

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
          doc_key.downcase.gsub(/[`]/, '') == this_key.downcase
        }
      }.first

      # return the item-hash of this doc with the key used to select it...
      { doc: doc, key: key}

    }
# raise
    # Sort our retrieved docs by their key
    # item_hash_list.sort!{ |x,y|
    #   x[:key] <=> y[:key]
    # }
# if count > 0 
#   raise
# end

    # Sort by Call-Number, secondary sort by Bib for matching call-numbers,
    # and remember to reverse the Bib sort when dealing with reverse shelfkeys.
    if fieldname == 'shelfkey'
      item_hash_list = item_hash_list.sort_by { |x| [ x[:key], x[:doc].id.to_i ] }
    elsif fieldname == 'reverse_shelfkey'
      item_hash_list = item_hash_list.sort_by { |x| [ x[:key], (0 - x[:doc].id.to_i) ] }
    end

    # Use the key to fetch the matching item_display jumbo field,
    # parse it out into separate fields
    item_hash_list.each { |item|
      # raise unless item[:key].starts_with? 'loc'
      item[:current_call_number]      = get_call_number(get_item_display(item, item[:key]) )
      item[:current_shelfkey]         = get_shelfkey(get_item_display(item, item[:key]) )
      item[:current_reverse_shelfkey] = get_reverse_shelfkey(get_item_display(item, item[:key]) )
    }

    # If we were unable to fill in current-X values, something's wrong with
    # this record.  Suppress this item from the browse displays.
    item_hash_list.delete_if { |item| item[:current_call_number].nil? }

# raise

    # return only the correct number of items
    # (duplicate shelfkeys could have bumped up document count)
    return item_hash_list[0..count]
  end



  def get_next_terms(curr_value, field, how_many)
    Rails.logger.debug "entering get_next_terms(#{curr_value}, #{field}, #{how_many})"

    # TermsComponent Query to get the terms
    solr_params = {
      'terms.fl' => field,
      'terms.lower' => curr_value,
      'terms.sort' => 'index',
      'terms.limit' => how_many
    }
    solr_response = Blacklight.default_index.connection.alphaTerms({params: solr_params})

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

    Rails.logger.debug "get_next_terms returning result:  #{result.inspect}"

    result
  end




  def shelfkey_to_reverse_shelfkey(item, shelfkey)
    # fetch the correct item_display jumbo field
    item_display_field = get_item_display(item, shelfkey)

    # dig out the correct sub-component of the jumbo field
    reverse_shelfkey = get_reverse_shelfkey(item_display_field)
    raise unless reverse_shelfkey

    return reverse_shelfkey
  end



  def nearby_SearchWorks
    return unless params[:start].present?

    @response, @document = fetch(params[:start])

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


end

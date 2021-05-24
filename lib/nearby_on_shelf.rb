# Call Number Browse
#
# Based on Stanford SearchWorks
#

class NearbyOnShelf
  include Blacklight::SearchHelper

  attr_reader :items

  def initialize(type, config, options)
    # raise
    @blacklight_config = config
    if type == 'ajax'
      starting_value = options[:start].downcase
      @items = get_next_spines_from_field(starting_value, options[:field], options[:num], nil)
    else
      @items = get_nearby_items(options[:item_display], options[:preferred_barcode], options[:before], options[:after], options[:page])
    end
  end

  # def shelfkey_to_browse_list
  #   puts "TEST"
  # end

  protected

  # ???
  def logger
    ::Rails.logger
  end

  attr_reader :blacklight_config

  def params
    {}
  end

  def get_nearby_items(itm_display, barcode, before, after, page)
    items = []
    item_display = get_item_display(itm_display, barcode)

    unless item_display.nil?
      my_shelfkey = get_shelfkey(item_display).downcase
      my_reverse_shelfkey = get_reverse_shelfkey(item_display).downcase

      if page.nil? || page.to_i.zero?
        # get preceding bookspines
        items << get_next_spines_from_field(my_reverse_shelfkey, 'reverse_shelfkey', before, nil)
        # TODO: can we avoid this extra call to Solr but keep the code this clean?
        # What is the purpose of this call?  To just return the original document?
        items << get_spines_from_field_values([my_shelfkey], 'shelfkey').uniq
        # get following bookspines
        items << get_next_spines_from_field(my_shelfkey, 'shelfkey', after, nil)
      else
        if page.to_i < 0 # page is negative so we need to get the preceding docs
          items << get_next_spines_from_field(my_reverse_shelfkey, 'reverse_shelfkey', (before.to_i + 1) * 2, page.to_i)
        elsif page.to_i > 0 # page is possitive, so we need to get the following bookspines
          items << get_next_spines_from_field(my_shelfkey, 'shelfkey', after.to_i * 2, page.to_i)
        end
      end
      # raise
      items.flatten
    end
  end # get_nearby_items

  # given a shelfkey or reverse shelfkey (for a lopped call number), get the
  #  text for the next "n" nearby items
  def get_next_spines_from_field(starting_value, field_name, how_many, page)
    number_of_items = how_many
    unless page.nil?
      page = page.to_s[1, page.to_s.length] if page < 0
      number_of_items = how_many.to_i * page.to_i + 1
    end
    desired_values = get_next_terms_for_field(starting_value, field_name, number_of_items)
    unless page.nil? || page.to_i.zero?
      desired_values = desired_values.values_at((desired_values.length - how_many.to_i)..desired_values.length)
    end
    get_spines_from_field_values(desired_values, field_name)
  end

  # create an array of sorted html list items containing the appropriate display text
  #  (analogous to what would be visible if you were looking at the spine of
  #  a book on a shelf) from relevant solr docs, given a particular solr
  #  field and value for which to retrieve spine info.
  # Each html list item must match a desired value
  def get_spines_from_field_values(desired_values, field)
    spines_hash = {}
    response, docs = get_solr_response_for_field_values(field, desired_values.compact)
    # SUL switched to this.  Worked for them, not for me.
    # response, docs = search_results(q: { field => desired_values.compact})
    docs.each do |doc|
      hsh = get_spine_hash_from_doc(doc, desired_values.compact, field)
      spines_hash.merge!(hsh) unless hsh.nil?
    end
    result = []
    spines_hash.keys.sort.each do |sortkey|
      result << spines_hash[sortkey]
    end
    result
  end

  # create a hash with
  #     key = sorting key for the spine,
  #     value = the html list item containing appropriate display text
  #  (analogous to what would be visible if you were looking at the spine of
  #  a book on a shelf) from a solr doc.
  #   spine is:  <li> title [(pub year)] [<br/> author] <br/> callnum </li>
  # Each element of the hash must match a desired value in the
  #   desired_values array for the indicated piece (shelfkey or reverse shelfkey)
  def get_spine_hash_from_doc(doc, _desired_values, _field)
    # raise
    result_hash = {}
    return if doc[:item_display].nil?

    # marquis, short-circuit all the below logic...
    sort_key = doc[:item_display]
    result_hash[sort_key] = { doc: doc }
    result_hash
  end
end

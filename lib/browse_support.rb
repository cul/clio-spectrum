
# NOTE - this support library is read in once during initialization.
# When this file is modified, the Rails server needs to be restarted.


module BrowseSupport

  # Whichever controller includes's this module will also thereby 
  # invoke helper_method() on each method to make them available in views.
  # http://www.seanbehan.com/make-rails-lib-module-methods-available-to-views
  def self.included(base)
    base.send :helper_method, :get_call_number, :get_shelfkey, :get_reverseshelfkey if base.respond_to? :helper_method
  end


  # given a document and the barcode of an item in the document, return the
  #  item_display field corresponding to the barcode, or nil if there is no
  #  such item
  def get_item_display(item, key)
    # raise
    # Accept a "browse item" structure, or a plain old SolrDocument
    if item.has_key? :item_display
      item_display = item[:item_display]
    else
      item_display = item[:doc][:item_display]
    end
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


end



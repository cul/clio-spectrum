class SavedList < ApplicationRecord
  # attr_accessible :owner, :name, :slug, :description, :sort_by, :permissions
  has_many :saved_list_items, dependent: :destroy
  has_paper_trail

  SERVICE_URL_PREFIX = '/lists'.freeze
  DEFAULT_LIST_NAME = 'Bookbag'.freeze
  DEFAULT_LIST_SLUG = 'bookbag'.freeze

  # stringex
  acts_as_url :name, url_attribute: :slug, scope: :owner, sync_url: true

  def is_default?
    name == DEFAULT_LIST_NAME
  end

  def url
    url = "#{SERVICE_URL_PREFIX}/#{owner}/#{slug}"
    url
  end

  def size
    saved_list_items.size
  end

  def display_name
    return DEFAULT_LIST_NAME if is_default?
    name
  end

  def add_items_by_key(item_key_list)
    # Force to Array
    item_key_list = Array(item_key_list)
    # What items are already in this list?
    current_item_keys = saved_list_items.map(&:item_key)
    # Add any new items, count as we go
    add_count = 0
    (item_key_list - current_item_keys).uniq.each do |item_key|
      new_item = SavedListItem.new(item_key: item_key, saved_list_id: id)
      begin
        new_item.save!
      rescue ActiveRecord::RecordNotUnique
        # Sometimes, somehow, we try to save an item which has already
        # been saved.  Ignore this when it happens.
      end
      add_count += 1
      # touch this list to update timestamps, etc.
      touch
    end
    add_count
  end
end

class SavedListItem < ActiveRecord::Base
  attr_accessible :item_key, :saved_list_id, :sort_order
  belongs_to :saved_list
  has_paper_trail
end

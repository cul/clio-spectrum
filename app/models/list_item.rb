class ListItem < ActiveRecord::Base
  attr_accessible :item_key, :list_id, :sort_order
  belongs_to :list
end

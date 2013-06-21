class MyListItem < ActiveRecord::Base
  attr_accessible :item_key, :my_list_id, :sort_order
  belongs_to :my_list
end

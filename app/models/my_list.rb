class MyList < ActiveRecord::Base
  attr_accessible :owner, :name, :slug, :description, :sort_by, :permissions
  has_many :my_list_items
  
  # stringex
  acts_as_url :name, :url_attribute => :slug, :scope => :owner, :sync_url => true
end

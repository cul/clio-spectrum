class List < ActiveRecord::Base
  attr_accessible :created_by, :description, :name, :permissions
  has_many :list_items
end

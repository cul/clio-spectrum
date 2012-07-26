class DatabaseAlert < ActiveRecord::Base
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"

  attr_accessible :active, :author_id, :clio_id, :message

  validates :author_id, :presence => true
  validates :message, :presence => true
  validates :clio_id, :uniqueness => true, :presence => true


end

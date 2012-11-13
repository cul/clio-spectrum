class DatabaseAlert < ActiveRecord::Base
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"

  attr_accessible :source, :item_id, :author_id, :alert_type, :start_time, :end_time, :message

  validates :author_id, :presence => true
  validates :message, :presence => true
  validates :source, :presence => true
  validates :item_id, :presence => true
  validates_uniqueness_of :item_id, :scope => [:source, :alert_type]


end

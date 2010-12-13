class Library < ActiveRecord::Base
  validates_uniqueness_of :hours_db_code
  has_many :hours, :class_name => "LibraryHours", :dependent => :destroy

  

end

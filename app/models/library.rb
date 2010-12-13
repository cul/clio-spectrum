class Library < ActiveRecord::Base
  validates_uniqueness_of :hours_db_code


end

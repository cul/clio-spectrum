class Location < ActiveRecord::Base
  attr_accessible :name, :found_in, :library_id, :has_info
end

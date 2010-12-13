class Location < ActiveRecord::Base
  CATEGORIES = %w{library info}
  attr_accessible :name, :found_in, :library_id, :category
  
  has_options :association_name => :links


  def self.match_location_text(location = nil)
    matches = self.find(:all, :conditions => ["? LIKE CONCAT(locations.name, '%')", location])
    max_length = matches.collect { |m| m.name.length }.max
    matches.detect { |m| m.name.length == max_length }
    
  end
end

class AddLocationCodeToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :location_code, :text
  end
end

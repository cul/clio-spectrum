class AddLibraryCodeToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :library_code, :text
  end
end

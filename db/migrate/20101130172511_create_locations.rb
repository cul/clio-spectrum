class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :name
      t.text :found_in
      t.integer :library_id
      t.string :category, limit: 10
      t.timestamps null: true
    end

    add_index :locations, :name
    add_index :locations, :library_id
  end

  def self.down
    drop_table :locations
  end
end

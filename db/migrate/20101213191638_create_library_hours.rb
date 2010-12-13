class CreateLibraryHours < ActiveRecord::Migration
  def self.up
    create_table :library_hours do |t|
      t.integer :library_id, :null => false
      t.date :date, :null => false
      t.datetime :open
      t.datetime :close
      t.text :note

      t.timestamps
    end

    add_index :library_hours, [:library_id, :date]
  end

  def self.down
    drop_table :library_hours
  end
end

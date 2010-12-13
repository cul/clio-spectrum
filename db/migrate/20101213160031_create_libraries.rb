class CreateLibraries < ActiveRecord::Migration
  def self.up
    create_table :libraries do |t|
      t.string :hours_db_code, :length => 30, :null => false
      t.string :name
      t.text :comment
      t.text :url

      t.timestamps
    end

    add_index :libraries, :hours_db_code
  end

  def self.down
    drop_table :libraries
  end
end

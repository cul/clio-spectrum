class CreateMyLists < ActiveRecord::Migration
  def change
    create_table :my_lists do |t|
      t.string :owner, :null => false
      t.string :name, :null => false
      t.string :slug, :null => false
      t.string :description, :default => ''
      t.string :sort_by
      t.string :permissions, :default => "private"

      t.timestamps
    end
    
    add_index :my_lists, [:owner, :slug], :unique => true, :name => "mylist_url"
    add_index :my_lists, [:owner, :name], :unique => true, :name => "mylist_name"
    
  end
end

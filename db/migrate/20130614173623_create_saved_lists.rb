class CreateSavedLists < ActiveRecord::Migration
  def change
    create_table :saved_lists do |t|
      t.string :owner, :null => false, :limit => 20
      t.string :name, :null => false, :limit => 200
      t.string :slug, :null => false, :limit => 200
      t.string :description, :default => ''
      t.string :sort_by
      t.string :permissions, :default => "private"

      t.timestamps
    end

    add_index :saved_lists, [:owner, :slug], :unique => true, :name => "savedlist_url"
    add_index :saved_lists, [:owner, :name], :unique => true, :name => "savedlist_name"

  end
end

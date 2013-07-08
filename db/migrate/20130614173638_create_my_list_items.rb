class CreateMyListItems < ActiveRecord::Migration
  def change
    create_table :my_list_items do |t|
      t.integer :my_list_id
      t.string :item_source
      t.string :item_key, :length => 200
      t.integer :sort_order

      t.timestamps
    end
    
    add_index :my_list_items, [:my_list_id, :item_key], :unique => true
    
  end
end

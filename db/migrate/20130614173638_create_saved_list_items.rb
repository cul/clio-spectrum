class CreateSavedListItems < ActiveRecord::Migration
  def change
    create_table :saved_list_items do |t|
      t.integer :saved_list_id
      t.string :item_source
      t.string :item_key, limit: 200
      t.integer :sort_order

      t.timestamps
    end

    add_index :saved_list_items, [:saved_list_id, :item_key], unique: true
  end
end

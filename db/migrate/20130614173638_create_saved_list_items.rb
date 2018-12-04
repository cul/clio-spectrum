class CreateSavedListItems < ActiveRecord::Migration[5.1]
  def change
    create_table :saved_list_items do |t|
      t.integer :saved_list_id
      t.string :item_source
      t.text :item_key
      t.integer :sort_order

      t.timestamps null: true
    end

    # add_index :saved_list_items, [:saved_list_id, :item_key], unique: true

    add_index :saved_list_items, [:saved_list_id, :item_key], unique: true, length: { item_key: 200 }
  end
end

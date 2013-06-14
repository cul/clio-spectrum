class CreateListItems < ActiveRecord::Migration
  def change
    create_table :list_items do |t|
      t.integer :list_id
      t.string :item_key
      t.integer :sort_order

      t.timestamps
    end
  end
end

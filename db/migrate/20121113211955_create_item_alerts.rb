class CreateItemAlerts < ActiveRecord::Migration
  def change
    create_table :item_alerts do |t|
      t.string :source, :null => false
      t.string :item_key, :null => false
      t.string :alert_type, :null => false
      t.integer :author_id
      t.datetime :start_date
      t.datetime :end_date
      t.text :message

      t.timestamps
    end

    add_index :item_alerts, [:source, :item_key]
    add_index :item_alerts, [:start_date, :end_date]

  end
end

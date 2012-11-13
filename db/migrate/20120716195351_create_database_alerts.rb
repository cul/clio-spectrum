class CreateDatabaseAlerts < ActiveRecord::Migration
  def change
    create_table :database_alerts do |t|
      t.string :source, :null => false
      t.string :item_id, :null => false
      t.string :alert_type, :null => false
      t.integer :author_id
      t.datetime :start_time
      t.datetime :end_time
      t.text :message

      t.timestamps
    end

    add_index :database_alerts, [:source, :item_id]
    add_index :database_alerts, [:start_time, :end_time]
  end
end

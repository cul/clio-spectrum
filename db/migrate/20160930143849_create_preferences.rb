class CreatePreferences < ActiveRecord::Migration[5.1]
  def change
    create_table :preferences do |t|
      t.string :login, null: false
      t.text :settings, null: false

      t.timestamps null: false
    end

    add_index :preferences, :login, unique: true
  end
end

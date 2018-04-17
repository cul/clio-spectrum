class CreateUsers < ActiveRecord::Migration[5.1]
  def self.up
    create_table :users do |t|
      t.string :first_name, limit: 40
      t.string :last_name, limit: 40
      t.string :login, limit: 10
      t.timestamps null: true
    end

    add_index :users, :login
  end

  def self.down
    drop_table :locations
  end
end

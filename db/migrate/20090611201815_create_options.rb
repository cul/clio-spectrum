class CreateOptions < ActiveRecord::Migration
  def self.up
    create_table :options, force: true do |t|
      t.integer :entity_id
      t.string :entity_type, limit: 30
      t.string :association_type, limit: 30
      t.string :name, null: false
      t.text :value
      t.timestamps, null: true
    end

    add_index :options, [:entity_type, :entity_id, :association_type, :name], name: 'entity_association_name'
  end

  def self.down
    drop_table :options
  end
end

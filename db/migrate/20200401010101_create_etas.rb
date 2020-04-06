class CreateEtas < ActiveRecord::Migration[5.1]
  def change
    create_table :hathi_etas do |t|
      t.string :oclc, null: false
      t.string :local_id, null: false
      t.string :item_type, null: false
      t.string :access, null: true
      t.string :rights, null: true

      t.timestamps null: false
    end

    add_index :hathi_etas, :oclc, unique: false
    add_index :hathi_etas, :local_id, unique: true

  end
end

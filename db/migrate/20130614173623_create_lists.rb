class CreateLists < ActiveRecord::Migration
  def change
    create_table :lists do |t|
      t.string :name
      t.string :description
      t.string :created_by
      t.string :permissions

      t.timestamps
    end
  end
end

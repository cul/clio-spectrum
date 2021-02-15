class CreateSimplye < ActiveRecord::Migration[5.1]
  def change
    create_table :simplye_links do |t|
      # Id of Voyager Authority record.  
      # String instead of Int, because I don't trust source data
      t.string :bib_id, null: false
      t.string :simplye_url, null: true
      
      t.timestamps null: false
    end

    add_index :simplye_links, :bib_id, unique: true
 
  end
end
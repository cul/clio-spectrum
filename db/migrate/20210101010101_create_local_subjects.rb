class CreateLocalSubjects < ActiveRecord::Migration[5.1]
  def change
    create_table :local_subjects do |t|
      # Id of Voyager Authority record.  
      # String instead of Int, because I don't trust source data
      t.string :authority_id, null: false
      t.string :authority_field, null: true
      t.string :authority_subfield, null: true
      
      t.string :loc_subject, null: false
      t.string :nnc_subject, null: false


      t.timestamps null: false
    end

    add_index :local_subjects, :loc_subject, unique: true
 
  end
end
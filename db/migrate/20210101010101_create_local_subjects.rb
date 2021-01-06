class CreateLocalSubjects < ActiveRecord::Migration[5.1]
  def change
    create_table :local_subjects do |t|
      # Id of Voyager Authority record.  
      # String instead of Int, because I don't trust Voyager
      t.string :authority_id, null: true
      
      t.string :loc_subject, null: true
      t.string :nnc_subject, null: true

      t.timestamps null: false
    end
  end
end
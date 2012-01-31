class CreateLibraryWebDocuments < ActiveRecord::Migration
  def change
    create_table :library_web_documents do |t|

      t.timestamps
    end
  end
end

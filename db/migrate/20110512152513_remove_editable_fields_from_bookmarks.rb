class RemoveEditableFieldsFromBookmarks < ActiveRecord::Migration[5.1]
  def self.up
    remove_column :bookmarks, :notes
    remove_column :bookmarks, :url
  end

  def self.down
    add_column :bookmarks, :notes, :text
    add_column :bookmarks, :url, :string
  end
end

class AddUserTypesToBookmarksSearches < ActiveRecord::Migration[5.1]
  def self.up
    add_column :searches, :user_type, :string
    add_column :bookmarks, :user_type, :string
  end

  def self.down
    remove_column :searches, :user_type, :string
    remove_column :bookmarks, :user_type, :string
  end
end

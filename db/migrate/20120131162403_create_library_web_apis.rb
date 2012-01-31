class CreateLibraryWebApis < ActiveRecord::Migration
  def change
    create_table :library_web_apis do |t|

      t.timestamps
    end
  end
end

class LibraryCode < ActiveRecord::Migration[5.1]

  def change

    add_column(:locations, :library_code, :string)
    
    add_index :locations, :library_code

    add_column(:library_hours, :library_code, :string)
    
    add_index :library_hours, :library_code

  end

end


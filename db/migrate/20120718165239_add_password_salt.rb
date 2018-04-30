class AddPasswordSalt < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :password_salt, :string
  end
end

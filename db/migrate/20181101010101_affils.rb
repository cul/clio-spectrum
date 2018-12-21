# Changes to enable omniauth-cas-saml based affils
class Affils < ActiveRecord::Migration[5.1]


  # def change
  # 
  #   rename_column :users, :login, :uid
  # 
  #   add_column :users, :provider, :string, null: false, default: 'saml'
  # 
  #   add_column :users, :affils, :text
  # 
  # end

  def self.up
    add_column :users, :provider, :string, null: false, default: 'saml'
    add_column :users, :affils, :text
    add_column :users, :uid, :string

    User.update_all("uid=login")

    add_index :users, :uid
  end
  
  def self.down
    remove_column :users, :provider, :string
    remove_column :users, :affils, :text
    remove_column :users, :uid, :string
  end

end


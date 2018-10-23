# Changes to enable omniauth-cas-saml based affils
class Affils < ActiveRecord::Migration[5.1]


  def change

    rename_column :users, :login, :uid

    add_column :users, :provider, :string, null: false, default: 'saml'

    add_column :users, :affils, :text

  end

end


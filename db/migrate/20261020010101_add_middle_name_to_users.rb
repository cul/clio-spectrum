# Columbia LDAP "cumiddlename", set by User#set_personal_info_via_ldap
class AddMiddleNameToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :middle_name, :string, limit: 40, after: :first_name
  end
end

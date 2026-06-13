class AllowUsersInMultipleOrganizations < ActiveRecord::Migration[8.1]
  def up
    remove_index :memberships, name: "index_memberships_on_user_id_unique" if index_exists?(:memberships, :user_id, name: "index_memberships_on_user_id_unique")
    add_index :memberships, :user_id unless index_exists?(:memberships, :user_id)
  end

  def down
    remove_index :memberships, :user_id if index_exists?(:memberships, :user_id, name: "index_memberships_on_user_id")
    add_index :memberships, :user_id, unique: true, name: "index_memberships_on_user_id_unique" unless index_exists?(:memberships, :user_id, unique: true)
  end
end

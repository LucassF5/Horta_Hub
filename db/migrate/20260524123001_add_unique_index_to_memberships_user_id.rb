class AddUniqueIndexToMembershipsUserId < ActiveRecord::Migration[8.1]
  def change
    remove_index :memberships, :user_id if index_exists?(:memberships, :user_id) && !index_exists?(:memberships, :user_id, unique: true)

    add_index :memberships, :user_id, unique: true, name: 'index_memberships_on_user_id_unique' unless index_exists?(:memberships, :user_id, unique: true)
  end
end

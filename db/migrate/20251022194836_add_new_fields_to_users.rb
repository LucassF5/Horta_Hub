class AddNewFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string, null: false
    add_column :users, :role, :string, default: "user", null: false
  end
end

class CreateOrganizationsAndMemberships < ActiveRecord::Migration[8.1]
  def up
    create_table :organizations do |t|
      t.string :name, null: false, limit: 100
      t.string :slug, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    add_index :organizations, :slug, unique: true

    create_table :memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "viewer"
      t.timestamps
    end

    add_index :memberships, [:organization_id, :user_id], unique: true

    add_column :products, :organization_id, :integer, null: false
    add_foreign_key :products, :organizations

    add_column :clients, :organization_id, :integer, null: false
    add_foreign_key :clients, :organizations

    remove_column :users, :role
  end

  def down
    add_column :users, :role, :string, null: false, default: "user"

    remove_foreign_key :clients, :organizations
    remove_column :clients, :organization_id

    remove_foreign_key :products, :organizations
    remove_column :products, :organization_id

    remove_index :memberships, column: [:organization_id, :user_id]
    drop_table :memberships

    remove_index :organizations, :slug
    drop_table :organizations
  end
end

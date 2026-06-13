class AddSlugsToProductsAndClients < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :slug, :string
    add_column :clients, :slug, :string

    add_index :products, [ :organization_id, :slug ], unique: true
    add_index :clients, [ :organization_id, :slug ], unique: true
  end
end

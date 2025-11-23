class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :name, limit: 65, null: false
      t.string :phone
      t.string :client_type, null: false

      t.timestamps
    end
  end
end

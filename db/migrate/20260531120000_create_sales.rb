class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.date :sale_date, null: false
      t.decimal :total, precision: 10, scale: 2, null: false, default: 0
      t.string :status, default: "pending", null: false
      t.text :notes

      t.timestamps
    end

    add_index :sales, [ :organization_id, :sale_date ]
  end
end

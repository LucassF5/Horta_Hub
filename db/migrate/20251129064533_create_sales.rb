class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.date :sale_date, null: false
      t.string :payment_status, null: false
      t.string :payment_type, null: false
      t.text :observations, limit: 255
      t.decimal :total_amount, precision: 10, scale: 2
      t.references :user, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end

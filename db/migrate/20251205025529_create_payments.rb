class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :sale, null: false, foreign_key: true
      t.string :payment_method, null: false
      t.string :status, null: false
      t.decimal :amount
      t.datetime :paid_at

      t.timestamps
    end
  end
end

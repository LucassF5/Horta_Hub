class RemovePaymentsFromSale < ActiveRecord::Migration[8.1]
  def change
    remove_column :sales, :payment_status, :string
    remove_column :sales, :payment_type, :string
  end
end

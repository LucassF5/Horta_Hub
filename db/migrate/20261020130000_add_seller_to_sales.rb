class AddSellerToSales < ActiveRecord::Migration[8.1]
  def change
    add_reference :sales, :seller, foreign_key: { to_table: :users }
  end
end

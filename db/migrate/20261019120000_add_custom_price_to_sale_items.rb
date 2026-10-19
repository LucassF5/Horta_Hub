class AddCustomPriceToSaleItems < ActiveRecord::Migration[8.1]
  def change
    add_column :sale_items, :custom_price, :boolean, default: false, null: false
  end
end

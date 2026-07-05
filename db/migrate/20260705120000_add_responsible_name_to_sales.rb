class AddResponsibleNameToSales < ActiveRecord::Migration[8.1]
  def change
    add_column :sales, :responsible_name, :string
  end
end

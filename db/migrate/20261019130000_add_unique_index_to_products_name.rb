class AddUniqueIndexToProductsName < ActiveRecord::Migration[8.1]
  class MigrationProduct < ActiveRecord::Base
    self.table_name = "products"
  end

  def up
    MigrationProduct.find_each do |product|
      normalized_name = product.name.squish.downcase.titleize
      product.update_columns(name: normalized_name) if product.name != normalized_name
    end

    duplicates = MigrationProduct.group(:organization_id, :name).having("COUNT(*) > 1").count
    if duplicates.any?
      details = duplicates.keys.map { |organization_id, name| "organization_id=#{organization_id} name=#{name}" }
      raise "Produtos duplicados impedem o índice único (resolva antes de migrar): #{details.join('; ')}"
    end

    add_index :products, [ :organization_id, :name ], unique: true
  end

  def down
    remove_index :products, [ :organization_id, :name ]
  end
end

class SaleItem < ApplicationRecord
  belongs_to :sale
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validate :product_must_belong_to_sale_organization

  before_validation :apply_product_price, unless: :custom_price?

  private

  # Sem preço personalizado, o item usa o preço padrão do produto. Itens já salvos
  # mantêm o preço registrado para preservar o histórico da venda.
  def apply_product_price
    return if product.blank?

    if new_record? || will_save_change_to_product_id? || will_save_change_to_custom_price?
      self.unit_price = product.price
    else
      restore_attributes([ :unit_price ])
    end
  end

  def product_must_belong_to_sale_organization
    return if sale.blank? || product.blank?
    return if product.organization_id == sale.organization_id

    errors.add(:product, "deve pertencer à mesma organização da venda")
  end
end

# == Schema Information
#
# Table name: sale_items
#
#  id           :integer          not null, primary key
#  custom_price :boolean          default(FALSE), not null
#  quantity     :integer          default(1), not null
#  unit_price   :decimal(10, 2)   not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  product_id   :integer          not null
#  sale_id      :integer          not null
#
# Indexes
#
#  index_sale_items_on_product_id  (product_id)
#  index_sale_items_on_sale_id     (sale_id)
#
# Foreign Keys
#
#  product_id  (product_id => products.id)
#  sale_id     (sale_id => sales.id)
#

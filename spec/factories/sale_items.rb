FactoryBot.define do
  factory :sale_item do
    quantity { Faker::Number.between(from: 1, to: 10) }
    unit_price { Faker::Commerce.price(range: 1.0..100.0) }
    association :sale
    association :product
  end
end

# == Schema Information
#
# Table name: sale_items
#
#  id         :integer          not null, primary key
#  quantity   :integer          default(1), not null
#  unit_price :decimal(10, 2)   not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :integer          not null
#  sale_id    :integer          not null
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

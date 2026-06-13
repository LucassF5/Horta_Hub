FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    price { Faker::Commerce.price(range: 1.0..100.0) }
    association :organization

    trait :expensive do
      price { Faker::Commerce.price(range: 100.0..500.0) }
    end

    trait :cheap do
      price { Faker::Commerce.price(range: 1.0..10.0) }
    end

    trait :invalid do
      name { "" }
      price { nil }
    end
  end
end

# == Schema Information
#
# Table name: products
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  price           :decimal(10, 2)   not null
#  slug            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_products_on_organization_id_and_slug  (organization_id,slug) UNIQUE
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#

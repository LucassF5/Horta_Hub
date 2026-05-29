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

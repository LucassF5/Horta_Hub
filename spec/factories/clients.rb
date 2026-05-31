FactoryBot.define do
  factory :client do
    sequence(:name) { |n| "Client #{n}" }
    phone { Faker::PhoneNumber.phone_number }
    client_type { "pessoa_fisica" }
    association :organization

    trait :pessoa_juridica do
      client_type { "pessoa_juridica" }
    end

    trait :without_phone do
      phone { nil }
    end

    trait :invalid do
      name { "" }
      client_type { nil }
    end
  end
end

FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :with_organization do
      after(:create) do |user|
        organization = create(:organization)
        create(:membership, user: user, organization: organization)
      end
    end
  end
end

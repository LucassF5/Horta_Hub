FactoryBot.define do
  factory :membership do
    association :user
    association :organization
    role { "owner" }

    trait :admin do
      role { "admin" }
    end

    trait :manager do
      role { "manager" }
    end

    trait :viewer do
      role { "viewer" }
    end
  end
end

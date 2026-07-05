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

# == Schema Information
#
# Table name: clients
#
#  id              :integer          not null, primary key
#  client_type     :string           not null
#  name            :string(65)       not null
#  phone           :string
#  slug            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_clients_on_organization_id_and_slug  (organization_id,slug) UNIQUE
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#

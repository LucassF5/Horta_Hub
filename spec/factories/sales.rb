FactoryBot.define do
  factory :sale do
    sale_date { Date.current }
    status { "pending" }
    notes { Faker::Lorem.sentence }
    association :organization
    client { association(:client, organization: organization) }

    trait :completed do
      status { "completed" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :with_items do
      after(:create) do |sale|
        create_list(:sale_item, 2, sale: sale)
        sale.save! # recalculate total
      end
    end

    trait :invalid do
      sale_date { nil }
      client { nil }
    end
  end
end

# == Schema Information
#
# Table name: sales
#
#  id              :integer          not null, primary key
#  notes           :text
#  sale_date       :date             not null
#  status          :string           default("pending"), not null
#  total           :decimal(10, 2)   default(0.0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  client_id       :integer          not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_sales_on_client_id                      (client_id)
#  index_sales_on_organization_id                (organization_id)
#  index_sales_on_organization_id_and_sale_date  (organization_id,sale_date)
#
# Foreign Keys
#
#  client_id        (client_id => clients.id)
#  organization_id  (organization_id => organizations.id)
#

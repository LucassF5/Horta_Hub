FactoryBot.define do
  factory :sale do
    sale_date { Date.current }
    status { "pending" }
    notes { Faker::Lorem.sentence }
    association :organization
    client { association(:client, organization: organization) }

    after(:build) do |sale|
      sale.sale_items << build(:sale_item, sale: sale) if sale.sale_items.empty?
    end

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
#  id               :integer          not null, primary key
#  notes            :text
#  responsible_name :string
#  sale_date        :date             not null
#  status           :string           default("pending"), not null
#  total            :decimal(10, 2)   default(0.0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  client_id        :integer          not null
#  organization_id  :integer          not null
#  seller_id        :integer
#
# Indexes
#
#  index_sales_on_client_id                      (client_id)
#  index_sales_on_organization_id                (organization_id)
#  index_sales_on_organization_id_and_sale_date  (organization_id,sale_date)
#  index_sales_on_seller_id                      (seller_id)
#
# Foreign Keys
#
#  client_id        (client_id => clients.id)
#  organization_id  (organization_id => organizations.id)
#  seller_id        (seller_id => users.id)
#

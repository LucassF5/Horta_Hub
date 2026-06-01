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

# == Schema Information
#
# Table name: memberships
#
#  id              :integer          not null, primary key
#  role            :string           default("viewer"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_memberships_on_organization_id              (organization_id)
#  index_memberships_on_organization_id_and_user_id  (organization_id,user_id) UNIQUE
#  index_memberships_on_user_id_unique               (user_id) UNIQUE
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#  user_id          (user_id => users.id)
#

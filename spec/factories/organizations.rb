FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:slug) { |n| "organization-#{n}" }
    status { "active" }
  end
end

# == Schema Information
#
# Table name: organizations
#
#  id         :integer          not null, primary key
#  name       :string(100)      not null
#  slug       :string           not null
#  status     :string           default("active"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organizations_on_slug  (slug) UNIQUE
#

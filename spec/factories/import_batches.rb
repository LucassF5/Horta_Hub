FactoryBot.define do
  factory :import_batch do
    organization { nil }
    user { nil }
    status { "MyString" }
    year { 1 }
    total_rows { 1 }
    processed_rows { 1 }
    successful_rows { 1 }
    failed_rows { 1 }
    error_details { "" }
    started_at { "2026-07-06 02:40:12" }
    finished_at { "2026-07-06 02:40:12" }
  end
end

# == Schema Information
#
# Table name: import_batches
#
#  id              :integer          not null, primary key
#  error_details   :json             not null
#  failed_rows     :integer          default(0), not null
#  finished_at     :datetime
#  processed_rows  :integer          default(0), not null
#  started_at      :datetime
#  status          :string           default("pending"), not null
#  successful_rows :integer          default(0), not null
#  total_rows      :integer          default(0), not null
#  year            :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_import_batches_on_organization_id  (organization_id)
#  index_import_batches_on_user_id          (user_id)
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#  user_id          (user_id => users.id)
#

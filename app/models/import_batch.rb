class ImportBatch < ApplicationRecord
  belongs_to :organization
  belongs_to :user
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

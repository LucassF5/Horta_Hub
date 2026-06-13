class Membership < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  enum :role, { owner: "owner", admin: "admin", manager: "manager", viewer: "viewer" }

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }

  def can_manage?
    owner? || admin? || manager?
  end

  def read_only?
    viewer?
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
#  index_memberships_on_user_id                      (user_id)
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#  user_id          (user_id => users.id)
#

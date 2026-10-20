class Membership < ApplicationRecord
  ROLES_BY_RANK = %w[viewer manager admin owner].freeze
  MANAGER_ROLES = %w[owner admin].freeze
  LAST_OWNER_MESSAGE = "a organização precisa de pelo menos um dono".freeze

  belongs_to :organization
  belongs_to :user

  enum :role, { owner: "owner", admin: "admin", manager: "manager", viewer: "viewer" }, validate: true

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }
  validate :organization_keeps_an_owner, on: :update

  before_destroy :prevent_destroying_last_owner

  def self.role_label(role)
    I18n.t("activerecord.attributes.membership.roles.#{role}")
  end

  def rank
    ROLES_BY_RANK.index(role)
  end

  def manages_members?
    role.in?(MANAGER_ROLES)
  end

  def assignable_roles
    roles = case role
    when "owner" then ROLES_BY_RANK
    when "admin" then ROLES_BY_RANK - %w[owner]
    else []
    end

    roles.reverse
  end

  def can_act_on_role?(role)
    role.to_s.in?(assignable_roles)
  end

  def role_label
    self.class.role_label(role)
  end

  def sole_organization?
    user.memberships.where.not(id: id).none?
  end

  private

  def last_owner?
    organization.memberships.owner.where.not(id: id).none?
  end

  def organization_keeps_an_owner
    return unless role_in_database == "owner" && !owner? && last_owner?

    errors.add(:role, LAST_OWNER_MESSAGE)
  end

  def prevent_destroying_last_owner
    return if destroyed_by_association&.active_record == Organization
    return unless role_in_database == "owner" && last_owner?

    errors.add(:base, LAST_OWNER_MESSAGE)
    throw :abort
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

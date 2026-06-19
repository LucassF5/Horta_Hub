# Base class for application policies
class ApplicationPolicy < ActionPolicy::Base
  authorize :membership
  authorize :organization

  private

  def can_manage?
    membership.owner? || membership.admin? || membership.manager?
  end

  def member?
    membership.present?
  end

  def same_organization?
    record.organization_id == membership.organization_id
  end
end

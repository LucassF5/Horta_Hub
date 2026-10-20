class MembershipPolicy < ApplicationPolicy
  alias_rule :new?, to: :create?
  alias_rule :edit?, to: :update?

  def index?
    membership.manages_members?
  end

  def create?
    membership.manages_members? && same_organization? && membership.can_act_on_role?(record.role)
  end

  def update?
    membership.manages_members? && same_organization? && !own_record? &&
      membership.can_act_on_role?(record.role_in_database) && membership.can_act_on_role?(record.role)
  end

  def destroy?
    membership.manages_members? && same_organization? && !own_record? &&
      membership.can_act_on_role?(record.role_in_database)
  end

  def reset_password?
    destroy? && record.sole_organization?
  end

  private

  def own_record?
    record.id == membership.id
  end
end

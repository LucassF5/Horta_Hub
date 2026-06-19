class ClientPolicy < ApplicationPolicy
  alias_rule :new?, to: :create?
  alias_rule :edit?, to: :update?

  def index?
    member?
  end

  def show?
    member? && same_organization?
  end

  def create?
    can_manage?
  end

  def update?
    can_manage? && same_organization?
  end

  def destroy?
    can_manage? && same_organization? && record.sales.empty?
  end
end

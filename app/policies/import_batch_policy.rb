class ImportBatchPolicy < ApplicationPolicy
  alias_rule :new?, to: :create?
  alias_rule :progress?, to: :show?

  def index?
    member?
  end

  def show?
    member? && same_organization?
  end

  def create?
    can_manage?
  end
end

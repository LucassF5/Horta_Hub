class ReportPolicy < ApplicationPolicy
  def show?
    can_manage?
  end
end

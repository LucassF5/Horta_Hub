class CurrentOrganizationsController < ApplicationController
  def update
    membership = Current.user.memberships.find_by(organization_id: params[:organization_id])

    if membership&.organization&.active?
      session[:organization_id] = membership.organization_id
      redirect_back_or_to root_path, notice: "Organização alterada com sucesso."
    else
      redirect_back_or_to root_path, alert: "Organização inválida."
    end
  end
end

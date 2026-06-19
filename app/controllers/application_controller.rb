class ApplicationController < ActionController::Base
  include Authentication

  rescue_from ActionPolicy::Unauthorized, with: :handle_unauthorized

  authorize :membership, through: :current_membership
  authorize :organization, through: :current_organization

  layout -> { Views::Layouts::ApplicationLayout }

  allow_browser versions: :modern

  private

  def handle_unauthorized
    redirect_to root_path, alert: "Você não tem permissão para realizar esta ação."
  end
end

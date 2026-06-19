class ApplicationController < ActionController::Base
  include Authentication

  authorize :membership, through: :current_membership
  authorize :organization, through: :current_organization

  layout -> { Views::Layouts::ApplicationLayout }

  allow_browser versions: :modern
end

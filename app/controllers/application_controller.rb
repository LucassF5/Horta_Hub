class ApplicationController < ActionController::Base
  include Authentication

  layout -> { Views::Layouts::ApplicationLayout }

  allow_browser versions: :modern
end

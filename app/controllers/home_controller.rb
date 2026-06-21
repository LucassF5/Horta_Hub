class HomeController < ApplicationController
  def index
    dashboard = Dashboard::OverviewQuery.new(organization: Current.organization)

    render Views::Home::Index.new(dashboard: dashboard)
  end
end

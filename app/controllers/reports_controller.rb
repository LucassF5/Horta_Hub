class ReportsController < ApplicationController
  def show
    authorize! :report

    filters = Reports::Filters.new(params.permit(:month, :comparison, :product_id, :seller), organization: Current.organization)
    render Views::Reports::Show.new(report: Reports::MonthlyReport.new(organization: Current.organization, filters: filters))
  end
end

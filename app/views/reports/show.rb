# frozen_string_literal: true

class Views::Reports::Show < Views::Base
  include Views::Reports::Formatting

  def initialize(report:)
    @report = report
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      render Components::PageHeader.new(title: "Relatórios", description: "Vendas concluídas de #{I18n.l(period.month, format: "%B de %Y")}.")
      render Views::Reports::FiltersComponent.new(report: report)
      render_metrics
      render_breakdown
    end
  end

  private

  attr_reader :report

  def period
    report.period
  end

  def render_breakdown
    comparison_label = window_label(period.base_windows.last)

    div(class: "mt-6 space-y-6") do
      render Views::Reports::YearChartComponent.new(points: report.year_points, selected_month: period.month)

      div(class: "grid gap-6 xl:grid-cols-2") do
        render Views::Reports::ProductsTableComponent.new(rows: report.product_rows, comparison_label: comparison_label)
        render Views::Reports::SellersTableComponent.new(rows: report.seller_rows, comparison_label: comparison_label)
      end
    end
  end

  def render_metrics
    summary = report.summary

    div(class: "grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-3") do
      render_metric_card(id: "revenue", title: "Receita", value: currency(summary.revenue.value), metric: summary.revenue)
      render_metric_card(id: "sales", title: "Vendas concluídas", value: summary.sales_count.value.to_s, metric: summary.sales_count)
      render_metric_card(id: "units", title: "Unidades vendidas", value: summary.units.value.to_s, metric: summary.units)
      render_metric_card(id: "ticket", title: "Ticket médio", value: currency(summary.ticket.value), metric: summary.ticket)
      render_status_card(id: "pending", title: "Pendentes", metric: summary.pending)
      render_status_card(id: "cancelled", title: "Canceladas", metric: summary.cancelled)
    end
  end

  def render_metric_card(id:, title:, value:, metric:)
    render Views::Reports::MetricCardComponent.new(id: id, title: title, value: value, comparisons: comparisons_for(metric))
  end

  def render_status_card(id:, title:, metric:)
    render Views::Reports::MetricCardComponent.new(
      id: id,
      title: title,
      value: metric.count.to_s,
      detail: "#{currency(metric.value)} · #{percent(metric.share)} das vendas do mês",
      comparisons: comparisons_for(metric),
      inverted: true
    )
  end

  # Comparação com a base sempre; com o mês atual, só quando o mês escolhido não é o atual.
  def comparisons_for(metric)
    comparisons = [ comparison(metric.change, period.base_windows.last) ]
    comparisons << comparison(metric.current_change, period.current_windows.last) if period.current_windows
    comparisons
  end

  def comparison(change, window)
    { change: change, label: window_label(window) }
  end

  def window_label(window)
    label = period_label(window)
    return label if window == window.first.all_month

    "#{label} (mesmos dias)"
  end
end

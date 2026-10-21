# frozen_string_literal: true

class Reports::Summary
  Metric = Data.define(:value, :change, :current_change)
  StatusMetric = Data.define(:count, :value, :share, :change, :current_change)

  COMPLETED = "completed"

  def initialize(scope:, period:)
    @scope = scope
    @period = period
  end

  def revenue = metric(:revenue)
  def sales_count = metric(:sales_count)
  def units = metric(:units)
  def ticket = metric(:ticket)
  def pending = status_metric("pending")
  def cancelled = status_metric("cancelled")

  private

  attr_reader :scope, :period

  def metric(attribute)
    Metric.new(
      value: stat(period.range, attribute),
      change: change(attribute, period.base_windows),
      current_change: change(attribute, period.current_windows)
    )
  end

  def status_metric(status)
    totals = scope.totals(period.range)
    selected = totals[status]

    StatusMetric.new(
      count: selected.sales_count,
      value: selected.revenue,
      share: Percentage.share(selected.sales_count, totals.values.sum(&:sales_count)),
      change: change(:sales_count, period.base_windows, status),
      current_change: change(:sales_count, period.current_windows, status)
    )
  end

  def change(attribute, windows, status = COMPLETED)
    return if windows.nil?

    selected, base = windows
    current = stat(selected, attribute, status)
    # Sem vendas no mês selecionado não há ticket; sem isso nil.to_d daria -100%.
    return if current.nil?

    Percentage.change(current, stat(base, attribute, status))
  end

  def stat(range, attribute, status = COMPLETED)
    scope.totals(range)[status].public_send(attribute)
  end
end

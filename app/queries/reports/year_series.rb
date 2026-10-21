# frozen_string_literal: true

class Reports::YearSeries
  Point = Data.define(:month, :revenue, :change, :state)

  def initialize(scope:, period:)
    @scope = scope
    @period = period
  end

  def points
    period.year_months.map { |month| point(month) }
  end

  private

  attr_reader :scope, :period

  def point(month)
    state = state_of(month)
    return Point.new(month: month, revenue: nil, change: nil, state: state) if state == :future

    Point.new(month: month, revenue: revenue(month), change: change(month, state), state: state)
  end

  def state_of(month)
    return :current if month == period.current_month
    return :future if month > period.current_month

    :past
  end

  def change(month, state)
    return current_change(month) if state == :current

    Percentage.change(revenue(month), revenue(month.prev_month))
  end

  def current_change(month)
    selected, base = Reports::Period.windows(month, month.prev_month, today: period.today)
    Percentage.change(scope.totals(selected)["completed"].revenue, scope.totals(base)["completed"].revenue)
  end

  def revenue(month)
    revenues.fetch(month.strftime("%Y-%m"), 0).to_d.round(2)
  end

  def revenues
    @revenues ||= scope
      .items(Date.new(period.month.year - 1, 12, 1)..Date.new(period.month.year, 12, 31))
      .group(Arel.sql("strftime('%Y-%m', sales.sale_date)"))
      .sum(Arel.sql("sale_items.quantity * sale_items.unit_price"))
  end
end

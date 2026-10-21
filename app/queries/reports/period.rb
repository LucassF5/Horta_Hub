# frozen_string_literal: true

class Reports::Period
  attr_reader :month, :comparison, :today

  def self.windows(month_a, month_b, today:)
    current = today.beginning_of_month
    return [ month_a.all_month, month_b.all_month ] unless [ month_a, month_b ].include?(current)

    [ month_a, month_b ].map { |month| month..[ month + (today.day - 1), month.end_of_month ].min }
  end

  def initialize(month:, comparison:, today: Date.current)
    @today = today
    @month = [ month.beginning_of_month, current_month ].min
    @comparison = resolve_comparison(comparison)
  end

  def current_month
    today.beginning_of_month
  end

  def current_month?
    month == current_month
  end

  def base_month
    comparison == :current ? current_month : month.prev_month
  end

  def range
    month.all_month
  end

  def base_windows
    self.class.windows(month, base_month, today: today)
  end

  def current_windows
    return if current_month? || comparison == :current

    self.class.windows(month, current_month, today: today)
  end

  def year_months
    (1..12).map { |number| Date.new(month.year, number, 1) }
  end

  private

  def resolve_comparison(value)
    return :previous if current_month? || value.to_s != "current"

    :current
  end
end

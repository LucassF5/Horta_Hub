# frozen_string_literal: true

# Módulo puro: não usa helpers do Phlex, para ser incluído em qualquer classe.
module Views::Reports::Formatting
  TONE_CLASSES = {
    positive: "text-green-700",
    negative: "text-red-700",
    neutral: "text-muted-foreground"
  }.freeze

  def currency(value)
    return "—" if value.nil?

    ActiveSupport::NumberHelper.number_to_currency(value)
  end

  def percent(value)
    return "—" if value.nil?

    ActiveSupport::NumberHelper.number_to_percentage(value, precision: 1)
  end

  def change_text(change)
    return "—" if change.nil?
    return percent(0) if change.zero?

    arrow = change.positive? ? "▲" : "▼"
    "#{arrow} #{percent(change.abs)}"
  end

  def change_tone(change, inverted: false)
    return :neutral if change.nil? || change.zero?

    good = inverted ? change.negative? : change.positive?
    good ? :positive : :negative
  end

  def tone_class(change, inverted: false) = TONE_CLASSES.fetch(change_tone(change, inverted: inverted))

  def period_label(range)
    month = I18n.l(range.first, format: "%b/%Y")
    return month if range == range.first.all_month

    "#{range.first.day} a #{range.last.day} de #{month}"
  end
end

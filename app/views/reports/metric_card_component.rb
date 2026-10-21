# frozen_string_literal: true

class Views::Reports::MetricCardComponent < Views::Base
  include Views::Reports::Formatting

  TONE_CLASSES = {
    positive: "text-green-700",
    negative: "text-red-700",
    neutral: "text-muted-foreground"
  }.freeze

  # comparisons: Array<{ change:, label: }>, sendo label o texto da janela de comparação.
  def initialize(id:, title:, value:, comparisons:, detail: nil, inverted: false)
    @id = id
    @title = title
    @value = value
    @comparisons = comparisons
    @detail = detail
    @inverted = inverted
  end

  def view_template
    render RubyUI::Card.new(id: "metric-#{@id}", class: "h-full min-w-0") do
      render RubyUI::CardHeader.new(class: "p-4 pb-2 sm:p-6 sm:pb-2") do
        render RubyUI::CardDescription.new { @title }
        render RubyUI::CardTitle.new(class: "break-words text-xl tabular-nums sm:text-3xl") { @value }
      end
      render RubyUI::CardContent.new(class: "p-4 pt-0 sm:p-6 sm:pt-0") do
        p(class: "text-xs text-muted-foreground") { @detail } if @detail

        div(class: "mt-1 space-y-0.5") do
          @comparisons.each { |comparison| render_comparison(comparison) }
        end
      end
    end
  end

  private

  def render_comparison(comparison)
    change = comparison[:change]
    label = comparison[:label]
    tone = change_tone(change, inverted: @inverted)
    text = change.nil? ? "Sem base em #{label}" : "#{change_text(change)} vs #{label}"

    p(class: [ "text-xs font-medium", TONE_CLASSES.fetch(tone) ]) { text }
  end
end

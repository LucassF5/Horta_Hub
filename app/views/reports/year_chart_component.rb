# frozen_string_literal: true

class Views::Reports::YearChartComponent < Views::Base
  include Views::Reports::Formatting

  # points: Array<Reports::YearSeries::Point>, um por mês do ano do mês escolhido.
  def initialize(points:, selected_month:)
    @points = points
    @selected_month = selected_month
    @max_revenue = points.filter_map(&:revenue).max || 0
  end

  def view_template
    render RubyUI::Card.new(id: "year-chart", class: "min-w-0") do
      render RubyUI::CardHeader.new(class: "p-4 pb-2 sm:p-6 sm:pb-2") do
        render RubyUI::CardTitle.new { "Evolução em #{@selected_month.year}" }
        render RubyUI::CardDescription.new { "Receita de vendas concluídas por mês e variação sobre o mês anterior." }
      end
      render RubyUI::CardContent.new(class: "p-4 pt-0 sm:p-6 sm:pt-0") do
        # Em telas pequenas as colunas rolam dentro do cartão em vez de espremer os rótulos.
        div(class: "relative overflow-x-auto") do
          div(class: "grid min-w-[40rem] grid-cols-12 gap-2") do
            @points.each { |point| render_column(point) }
          end
        end
        p(class: "mt-4 text-xs text-muted-foreground") { "* mês atual, em andamento" } if @points.any? { |point| point.state == :current }
      end
    end
  end

  private

  # Meses futuros mantêm a coluna com a mesma altura, sem variação, barra nem rótulo acessível.
  def render_column(point)
    future = point.state == :future

    div(class: "flex min-w-0 flex-col items-center gap-2", **column_attrs(point, future)) do
      p(class: [ "h-4 whitespace-nowrap text-[10px] font-medium", tone_class(point.change) ]) do
        change_text(point.change) unless future
      end

      div(class: "flex h-40 w-full items-end") do
        render_bar(point) unless future
      end

      span(class: "text-xs text-muted-foreground") { month_label(point) }
      span(class: "sr-only") { accessible_label(point) } unless future
    end
  end

  def column_attrs(point, future)
    future ? {} : { title: column_label(point) }
  end

  # A seleção aparece só por cor no gráfico; o texto acessível precisa dizê-la também.
  def accessible_label(point)
    return column_label(point) unless point.month == @selected_month

    "#{column_label(point)} (mês escolhido)"
  end

  def render_bar(point)
    color = point.month == @selected_month ? "bg-green-600" : "bg-green-300"

    div(class: [ "w-full rounded-t", color ], style: "height: #{bar_height(point.revenue)}%")
  end

  def bar_height(revenue)
    return 0 if @max_revenue.zero?

    (revenue / @max_revenue * 100).round
  end

  def month_label(point)
    label = I18n.l(point.month, format: "%b")
    point.state == :current ? "#{label}*" : label
  end

  def column_label(point)
    "#{period_label(point.month.all_month)}: #{currency(point.revenue)}"
  end
end

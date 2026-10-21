# frozen_string_literal: true

class Views::Reports::SellersTableComponent < Views::Base
  include Views::Reports::Formatting

  # rows: Array<Reports::SellerBreakdown::Row>; comparison_label: rótulo da janela da base.
  def initialize(rows:, comparison_label:)
    @rows = rows
    @comparison_label = comparison_label
  end

  def view_template
    render RubyUI::Card.new(id: "sellers-table", class: "min-w-0") do
      render RubyUI::CardHeader.new(class: "p-4 pb-2 sm:p-6 sm:pb-2") do
        render RubyUI::CardTitle.new { "Vendedores" }
        render RubyUI::CardDescription.new { "Vendas concluídas por responsável. Variação da receita contra #{@comparison_label}." }
      end
      render RubyUI::CardContent.new(class: "p-0") do
        if @rows.empty?
          render_empty_state
        else
          render_table
        end
      end
    end
  end

  private

  def render_empty_state
    div(class: "p-4 sm:p-6") do
      render Components::Listings::EmptyState.new(
        icon: PhlexIcons::Lucide::Users,
        title: "Nenhuma venda concluída neste mês",
        description: "Escolha outro mês ou remova os filtros."
      )
    end
  end

  def render_table
    render RubyUI::Table.new do
      render RubyUI::TableHeader.new do
        render RubyUI::TableRow.new do
          render RubyUI::TableHead.new(class: "pl-4 sm:pl-6") { "Vendedor" }
          render RubyUI::TableHead.new(class: "text-right") { "Vendas" }
          render RubyUI::TableHead.new(class: "text-right") { "Receita" }
          render RubyUI::TableHead.new(class: "text-right") { "% do total" }
          render RubyUI::TableHead.new(class: "pr-4 text-right sm:pr-6") { "Variação" }
        end
      end

      render RubyUI::TableBody.new do
        @rows.each { |row| render_row(row) }
      end
    end
  end

  def render_row(row)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new(class: "pl-4 font-medium sm:pl-6") { render_seller_name(row) }
      render RubyUI::TableCell.new(class: "text-right tabular-nums") { row.sales_count.to_s }
      render RubyUI::TableCell.new(class: "whitespace-nowrap text-right tabular-nums") { currency(row.revenue) }
      render RubyUI::TableCell.new(class: "text-right tabular-nums") { percent(row.share) }
      render RubyUI::TableCell.new(class: "whitespace-nowrap pr-4 text-right sm:pr-6") { render_variation(row) }
    end
  end

  def render_seller_name(row)
    case row.kind
    when :name
      plain row.name
      span(class: "ml-1 text-xs font-normal text-muted-foreground") { "(sem cadastro)" }
    when :none
      span(class: "font-normal text-muted-foreground") { row.name }
    else
      plain row.name
    end
  end

  def render_variation(row)
    span(class: [ "font-medium tabular-nums", tone_class(row.change) ]) { change_text(row.change) }
  end
end

# frozen_string_literal: true

class Views::Sales::Index < Views::Base
  def initialize(sales:)
    @sales = sales
  end

  def view_template
    div(class: "grow") do
      div(class: "container mx-auto px-4 py-8") do
        render_header
        render_content
      end
    end
  end

  private

  def render_header
    div(class: "flex justify-between items-center mb-6") do
      h1(class: "text-3xl font-bold text-gray-800") { "Vendas" }
      render RubyUI::Link.new(href: new_sale_path, variant: :primary) { "Nova Venda" } if allowed_to?(:create?, Sale)
    end
  end

  def render_content
    if @sales.empty?
      p(class: "text-gray-600") { "Nenhuma venda cadastrada ainda." }
    else
      render_table
    end
  end

  def render_table
    render RubyUI::Table.new do
      render RubyUI::TableHeader.new do
        render RubyUI::TableRow.new do
          render RubyUI::TableHead.new { "Data" }
          render RubyUI::TableHead.new { "Cliente" }
          render RubyUI::TableHead.new { "Status" }
          render RubyUI::TableHead.new { "Total" }
          render RubyUI::TableHead.new(class: "text-right") { "Ações" }
        end
      end

      render RubyUI::TableBody.new do
        @sales.each { |sale| render_sale_row(sale) }
      end
    end
  end

  def render_sale_row(sale)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new { l(sale.sale_date, format: :short) }
      render RubyUI::TableCell.new { sale.client.name }
      render RubyUI::TableCell.new { render_status_badge(sale) }
      render RubyUI::TableCell.new { number_to_currency(sale.total, unit: "R$ ") }
      render RubyUI::TableCell.new(class: "text-right") do
        div(class: "flex justify-end items-center gap-2") do
          render RubyUI::Link.new(href: sale_path(sale), variant: :outline) { "Ver" }
          render RubyUI::Link.new(href: edit_sale_path(sale), variant: :primary) { "Editar" } if allowed_to?(:edit?, sale)

          if allowed_to?(:destroy?, sale)
            form_with(
              url: sale_path(sale),
              method: :delete,
              local: true,
              style: "display: inline;"
            ) do
              render RubyUI::Button.new(
                type: :submit,
                variant: :destructive,
                data: { turbo_confirm: "Tem certeza?" }
              ) { "Apagar" }
            end
          end
        end
      end
    end
  end

  def render_status_badge(sale)
    color = case sale.status
    when "completed" then "text-green-700 bg-green-100"
    when "pending" then "text-yellow-700 bg-yellow-100"
    when "cancelled" then "text-red-700 bg-red-100"
    end

    label = case sale.status
    when "completed" then "Concluída"
    when "pending" then "Pendente"
    when "cancelled" then "Cancelada"
    end

    span(class: "px-2 py-1 rounded-full text-xs font-medium #{color}") { label }
  end
end

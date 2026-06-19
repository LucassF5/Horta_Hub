# frozen_string_literal: true

class Views::Sales::Show < Views::Base
  def initialize(sale:)
    @sale = sale
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      div(class: "bg-white shadow-md rounded-lg p-6 mb-8") do
        render_header
        render_details
        render_items
        render_actions
      end
    end
  end

  private

  def render_header
    div(class: "flex justify-between items-center mb-6") do
      h1(class: "text-3xl font-bold text-gray-800") { "Venda ##{@sale.id}" }
      render_status_badge
    end
  end

  def render_status_badge
    color = case @sale.status
    when "completed" then "text-green-700 bg-green-100"
    when "pending" then "text-yellow-700 bg-yellow-100"
    when "cancelled" then "text-red-700 bg-red-100"
    end

    label = case @sale.status
    when "completed" then "Concluída"
    when "pending" then "Pendente"
    when "cancelled" then "Cancelada"
    end

    span(class: "px-3 py-1 rounded-full text-sm font-medium #{color}") { label }
  end

  def render_details
    div(class: "grid grid-cols-1 md:grid-cols-3 gap-4 mb-6") do
      render_detail("Cliente", @sale.client.name)
      render_detail("Data", l(@sale.sale_date, format: :short))
      render_detail("Total", number_to_currency(@sale.total, unit: "R$ "))
    end

    if @sale.notes.present?
      div(class: "mb-6") do
        p(class: "text-sm font-semibold text-gray-500") { "Observações" }
        p(class: "text-gray-700") { @sale.notes }
      end
    end
  end

  def render_detail(label, value)
    div do
      p(class: "text-sm font-semibold text-gray-500") { label }
      p(class: "text-lg text-gray-800") { value }
    end
  end

  def render_items
    return if @sale.sale_items.empty?

    h2(class: "text-xl font-bold text-gray-800 mb-4") { "Itens da Venda" }

    render RubyUI::Table.new do
      render RubyUI::TableHeader.new do
        render RubyUI::TableRow.new do
          render RubyUI::TableHead.new { "Produto" }
          render RubyUI::TableHead.new { "Quantidade" }
          render RubyUI::TableHead.new { "Preço Unitário" }
          render RubyUI::TableHead.new { "Subtotal" }
        end
      end

      render RubyUI::TableBody.new do
        @sale.sale_items.includes(:product).each do |item|
          render RubyUI::TableRow.new do
            render RubyUI::TableCell.new { item.product.name }
            render RubyUI::TableCell.new { item.quantity.to_s }
            render RubyUI::TableCell.new { number_to_currency(item.unit_price, unit: "R$ ") }
            render RubyUI::TableCell.new { number_to_currency(item.quantity * item.unit_price, unit: "R$ ") }
          end
        end
      end
    end
  end

  def render_actions
    div(class: "flex gap-4 mt-6") do
      render RubyUI::Link.new(href: edit_sale_path(@sale), variant: :primary) { "Editar" } if allowed_to?(:edit?, @sale)

      if allowed_to?(:destroy?, @sale)
        form_with(
          url: sale_path(@sale),
          method: :delete,
          local: true,
          style: "display: inline;"
        ) do
          render RubyUI::Button.new(
            type: :submit,
            variant: :destructive,
            data: { turbo_confirm: "Tem certeza que deseja deletar esta venda?" }
          ) { "Deletar" }
        end
      end

      render RubyUI::Link.new(href: sales_path, variant: :outline) { "Voltar para Vendas" }
    end
  end
end

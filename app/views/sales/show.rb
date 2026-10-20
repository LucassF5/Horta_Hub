# frozen_string_literal: true

class Views::Sales::Show < Views::Base
  def initialize(sale:)
    @sale = sale
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div do
        render Components::PageHeader.new(
          title: "Venda ##{@sale.id}",
          back: [ "Voltar para vendas", sales_path ]
        ) do
          render RubyUI::Link.new(href: edit_sale_path(@sale), variant: :primary) { "Editar" } if allowed_to?(:edit?, @sale)
          render Components::DestroyButton.new(url: sale_path(@sale), confirm: "Tem certeza que deseja apagar esta venda?") if allowed_to?(:destroy?, @sale)
        end

        div(class: "grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]") do
          render_details
          render_items
        end
      end
    end
  end

  private

  def render_details
    render RubyUI::Card.new(class: "min-w-0 p-4 sm:p-6") do
      div(class: "mb-5 flex items-center justify-between gap-4 border-b pb-4") do
        div do
          p(class: "text-sm text-gray-500") { "Total" }
          p(class: "text-2xl font-bold tabular-nums text-gray-900") { number_to_currency(@sale.total) }
        end
        render Components::Sales::StatusBadge.new(status: @sale.status)
      end

      render Components::DetailList.new(items: [
        [ "Cliente", @sale.client.name ],
        [ "Data", l(@sale.sale_date, format: :long) ],
        ([ "Responsável", @sale.responsible_name ] if @sale.responsible_name.present?)
      ])

      if @sale.notes.present?
        div(class: "mt-5 border-t pt-4") do
          p(class: "text-sm text-gray-500") { "Observações" }
          p(class: "mt-1 whitespace-pre-line text-gray-900") { @sale.notes }
        end
      end
    end
  end

  def render_items
    items = @sale.sale_items.includes(:product)

    div(class: "min-w-0 rounded-lg border bg-white") do
      div(class: "p-4 sm:px-6") do
        h2(class: "font-semibold text-gray-900") { "Itens da Venda" }
        p(class: "text-sm text-gray-500") { pluralize(items.size, "item", plural: "itens") }
      end

      render RubyUI::Table.new do
        render RubyUI::TableHeader.new do
          render RubyUI::TableRow.new do
            render RubyUI::TableHead.new(class: "pl-4 sm:pl-6") { "Produto" }
            render RubyUI::TableHead.new(class: "hidden text-right sm:table-cell") { "Quantidade" }
            render RubyUI::TableHead.new(class: "hidden text-right sm:table-cell") { "Preço unitário" }
            render RubyUI::TableHead.new(class: "pr-4 text-right sm:pr-6") { "Subtotal" }
          end
        end

        render RubyUI::TableBody.new do
          items.each { |item| render_item_row(item) }
        end

        render RubyUI::TableFooter.new do
          render RubyUI::TableRow.new do
            render RubyUI::TableCell.new(class: "pl-4 font-semibold sm:pl-6") { "Total" }
            render RubyUI::TableCell.new(class: "hidden sm:table-cell")
            render RubyUI::TableCell.new(class: "hidden sm:table-cell")
            render RubyUI::TableCell.new(class: "pr-4 text-right font-semibold tabular-nums sm:pr-6") { number_to_currency(@sale.total) }
          end
        end
      end
    end
  end

  def render_item_row(item)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new(class: "pl-4 sm:pl-6") do
        p(class: "font-medium text-gray-900") { item.product.name }
        # Em telas pequenas quantidade e preço saem das colunas e aparecem sob o produto.
        p(class: "mt-0.5 text-xs tabular-nums text-gray-500 sm:hidden") { "#{item.quantity} × #{number_to_currency(item.unit_price)}" }
        p(class: "mt-0.5 text-xs text-gray-500") { "Preço personalizado" } if item.custom_price?
      end
      render RubyUI::TableCell.new(class: "hidden text-right tabular-nums sm:table-cell") { item.quantity.to_s }
      render RubyUI::TableCell.new(class: "hidden text-right tabular-nums sm:table-cell") { number_to_currency(item.unit_price) }
      render RubyUI::TableCell.new(class: "pr-4 text-right font-medium tabular-nums sm:pr-6") { number_to_currency(item.quantity * item.unit_price) }
    end
  end
end

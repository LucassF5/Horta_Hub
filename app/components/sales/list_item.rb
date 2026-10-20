# frozen_string_literal: true

# Linha de venda em listas resumidas (dashboard, cliente, produto).
class Components::Sales::ListItem < Components::Base
  # amount: valor exibido à direita; detail: texto extra ao lado da data.
  def initialize(sale:, title: sale.client.name, amount: sale.total, detail: nil)
    @sale = sale
    @title = title
    @amount = amount
    @detail = detail
  end

  def view_template
    li do
      a(
        href: sale_path(@sale),
        class: "flex items-center justify-between gap-4 rounded-md px-1 py-3 transition-colors hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-primary"
      ) do
        div(class: "min-w-0") do
          p(class: "truncate font-medium text-gray-900") { @title }
          # No celular o status desce para a linha da data e libera espaço para o título.
          div(class: "mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-gray-500") do
            span { l(@sale.sale_date, format: :short) }
            span { @detail } if @detail
            span(class: "sm:hidden") { render Components::Sales::StatusBadge.new(status: @sale.status) }
          end
        end
        div(class: "flex shrink-0 items-center gap-3") do
          span(class: "hidden sm:inline") { render Components::Sales::StatusBadge.new(status: @sale.status) }
          span(class: "font-medium tabular-nums text-gray-900") { number_to_currency(@amount) }
        end
      end
    end
  end
end

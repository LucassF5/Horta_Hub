# frozen_string_literal: true

class Views::Products::Show < Views::Base
  def initialize(product:, recent_items:, sales_count:, units_sold:)
    @product = product
    @recent_items = recent_items
    @sales_count = sales_count
    @units_sold = units_sold
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div do
        render Components::PageHeader.new(title: @product.name, back: [ "Voltar para produtos", products_path ]) do
          render_actions
        end

        div(class: "grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]") do
          render_details
          render_recent_sales
        end
      end
    end
  end

  private

  def render_actions
    render RubyUI::Link.new(href: edit_product_path(@product), variant: :primary) { "Editar" } if allowed_to?(:edit?, @product)

    render Components::DestroyButton.new(url: product_path(@product), confirm: "Tem certeza que deseja apagar este produto?") if allowed_to?(:destroy?, @product)
  end

  def render_details
    render RubyUI::Card.new(class: "min-w-0 p-4 sm:p-6") do
      render Components::DetailList.new(items: [
        [ "Preço", number_to_currency(@product.price) ],
        [ "Vendas", @sales_count.to_s ],
        [ "Unidades vendidas", @units_sold.to_s ]
      ])
    end
  end

  def render_recent_sales
    render RubyUI::Card.new(class: "min-w-0") do
      render RubyUI::CardHeader.new(class: "p-4 sm:p-6") do
        render RubyUI::CardTitle.new { "Vendas recentes" }
        render RubyUI::CardDescription.new { "Últimas vendas com este produto e o valor do item em cada uma." }
      end
      render RubyUI::CardContent.new(class: "p-4 pt-0 sm:p-6 sm:pt-0") do
        if @recent_items.empty?
          div(class: "rounded-lg border border-dashed border-gray-200 px-4 py-8 text-center text-sm text-gray-500") do
            "Este produto ainda não entrou em nenhuma venda."
          end
        else
          ul(class: "divide-y divide-gray-100") do
            @recent_items.each do |item|
              render Components::Sales::ListItem.new(
                sale: item.sale,
                amount: item.quantity * item.unit_price,
                detail: "#{item.quantity} × #{number_to_currency(item.unit_price)}"
              )
            end
          end
        end
      end
    end
  end
end

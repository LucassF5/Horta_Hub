# frozen_string_literal: true

class Views::Products::Index < Views::Base
  def initialize(products:)
    @products = products
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      render_header
      render_products_grid
    end
  end

  private

  def render_header
    div(class: "flex justify-between items-center mb-6") do
      h1(class: "text-3xl font-bold text-gray-800") { "Produtos" }
      render RubyUI::Link.new(href: new_product_path, variant: :primary) { "Novo Produto" } if allowed_to?(:create?, Product)
    end
  end

  def render_products_grid
    div(class: "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6") do
      @products.each do |product|
        render_product_card(product)
      end
    end
  end

  def render_product_card(product)
    render RubyUI::Card.new do
      render RubyUI::CardHeader.new do
        render RubyUI::CardTitle.new { product.name }
        render RubyUI::CardDescription.new do
          "Valor: #{number_to_currency(product.price)}"
        end
      end

      render RubyUI::CardFooter.new do
        div(class: "flex items-center justify-end gap-2") do
          render RubyUI::Link.new(href: product_path(product), variant: :outline) { "Ver" }
          render RubyUI::Link.new(href: edit_product_path(product), variant: :primary) { "Editar" } if allowed_to?(:edit?, product)

          if allowed_to?(:destroy?, product)
            form_with(
              url: product_path(product),
              method: :delete,
              local: true,
              style: "display: inline;"
            ) do
              render RubyUI::Button.new(
                type: :submit,
                variant: :destructive,
                data: { turbo_confirm: "Tem certeza que deseja apagar este produto?" }
              ) { "Apagar" }
            end
          end
        end
      end
    end
  end
end

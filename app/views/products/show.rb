# frozen_string_literal: true

class Views::Products::Show < Views::Base
  def initialize(product:)
    @product = product
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      h1(class: "text-3xl font-bold mb-6 text-gray-800") { @product.name }

      div(class: "bg-white shadow-md rounded-lg p-6 mb-8") do
        p(class: "text-gray-700 text-lg mb-4") do
          strong(class: "font-semibold") { "Preço: " }
          number_to_currency(@product.price)
        end

        div(class: "flex gap-4") do
          render RubyUI::Link.new(href: edit_product_path(@product), variant: :primary) { "Editar" }
          render RubyUI::Link.new(href: products_path, variant: :outline) { "Voltar para Produtos" }
        end
      end
    end
  end
end

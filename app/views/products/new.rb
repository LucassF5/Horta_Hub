# frozen_string_literal: true

class Views::Products::New < Views::Base
  def initialize(product:)
    @product = product
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div(class: "max-w-2xl") do
        render Components::PageHeader.new(
          title: "Novo Produto",
          description: "Cadastre um item que a organização vende.",
          back: [ "Voltar para produtos", products_path ]
        )
        render Components::Forms::Errors.new(record: @product, subject: "o produto")
        render Views::Products::FormComponent.new(product: @product, url: products_path, cancel_href: products_path)
      end
    end
  end
end

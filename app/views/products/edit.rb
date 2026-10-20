# frozen_string_literal: true

class Views::Products::Edit < Views::Base
  def initialize(product:)
    @product = product
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div(class: "max-w-2xl") do
        render Components::PageHeader.new(
          title: "Editar Produto",
          description: "Alterar o preço padrão não muda as vendas já registradas.",
          back: [ "Voltar para o produto", product_path(@product) ]
        )
        render Components::Forms::Errors.new(record: @product, subject: "o produto")
        render Views::Products::FormComponent.new(product: @product, url: product_path(@product), cancel_href: product_path(@product))
      end
    end
  end
end

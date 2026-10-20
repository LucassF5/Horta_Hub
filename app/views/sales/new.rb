# frozen_string_literal: true

class Views::Sales::New < Views::Base
  def initialize(sale:, clients:, products:)
    @sale = sale
    @clients = clients
    @products = products
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div(class: "max-w-4xl") do
        render Components::PageHeader.new(
          title: "Nova Venda",
          description: "Escolha o cliente e os produtos; o total é calculado pelos itens.",
          back: [ "Voltar para vendas", sales_path ]
        )
        render Components::Forms::Errors.new(record: @sale, subject: "a venda")
        render Views::Sales::FormComponent.new(
          sale: @sale,
          url: sales_path,
          clients: @clients,
          products: @products,
          cancel_href: sales_path
        )
      end
    end
  end
end

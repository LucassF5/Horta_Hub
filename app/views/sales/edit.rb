# frozen_string_literal: true

class Views::Sales::Edit < Views::Base
  def initialize(sale:, clients:, products:)
    @sale = sale
    @clients = clients
    @products = products
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div(class: "max-w-4xl") do
        render Components::PageHeader.new(
          title: "Editar Venda",
          back: [ "Voltar para a venda", sale_path(@sale) ]
        )
        render Components::Forms::Errors.new(record: @sale, subject: "a venda")
        render Views::Sales::FormComponent.new(
          sale: @sale,
          url: sale_path(@sale),
          clients: @clients,
          products: @products,
          cancel_href: sale_path(@sale)
        )
      end
    end
  end
end

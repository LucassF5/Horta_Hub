# frozen_string_literal: true

class Views::Clients::New < Views::Base
  def initialize(client:)
    @client = client
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div(class: "max-w-2xl") do
        render Components::PageHeader.new(
          title: "Novo Cliente",
          description: "Cadastre uma pessoa ou empresa que compra da organização.",
          back: [ "Voltar para clientes", clients_path ]
        )
        render Components::Forms::Errors.new(record: @client, subject: "o cliente")
        render Views::Clients::FormComponent.new(client: @client, url: clients_path, cancel_href: clients_path)
      end
    end
  end
end

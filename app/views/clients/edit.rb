# frozen_string_literal: true

class Views::Clients::Edit < Views::Base
  def initialize(client:)
    @client = client
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div(class: "max-w-2xl") do
        render Components::PageHeader.new(
          title: "Editar cliente",
          back: [ "Voltar para o cliente", client_path(@client) ]
        )
        render Components::Forms::Errors.new(record: @client, subject: "o cliente")
        render Views::Clients::FormComponent.new(client: @client, url: client_path(@client), cancel_href: client_path(@client))
      end
    end
  end
end

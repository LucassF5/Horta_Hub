# frozen_string_literal: true

class Views::Clients::Show < Views::Base
  def initialize(client:)
    @client = client
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      div(class: "bg-white shadow-md rounded-lg p-6 mb-8") do
        h1(class: "text-3xl font-bold mb-6 text-gray-800") { @client.name }

        p(class: "text-gray-700 text-lg mb-4") do
          strong(class: "font-semibold") { "Tipo do cliente: " }
          plain @client.client_type
        end

        if @client.phone.present?
          p(class: "text-gray-700 text-lg mb-4") do
            strong(class: "font-semibold") { "Telefone: " }
            plain @client.phone
          end
        end

        render_actions
      end
    end
  end

  private

  def render_actions
    div(class: "flex gap-4") do
      render RubyUI::Link.new(href: edit_client_path(@client), variant: :primary) { "Editar" } if allowed_to?(:edit?, @client)

      if allowed_to?(:destroy?, @client)
        form_with(
          url: client_path(@client),
          method: :delete,
          local: true,
          style: "display: inline;"
        ) do
          render RubyUI::Button.new(
            type: :submit,
            variant: :destructive,
            data: { turbo_confirm: "Tem certeza que deseja deletar este cliente?" }
          ) { "Deletar" }
        end
      end

      render RubyUI::Link.new(href: clients_path, variant: :outline) { "Voltar para Clientes" }
    end
  end
end

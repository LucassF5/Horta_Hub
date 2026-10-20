# frozen_string_literal: true

class Views::Clients::Show < Views::Base
  def initialize(client:, recent_sales:, sales_count:, total_bought:)
    @client = client
    @recent_sales = recent_sales
    @sales_count = sales_count
    @total_bought = total_bought
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div do
        render Components::PageHeader.new(title: @client.name, back: [ "Voltar para clientes", clients_path ]) do
          render RubyUI::Link.new(href: edit_client_path(@client), variant: :primary) { "Editar" } if allowed_to?(:edit?, @client)
          render Components::DestroyButton.new(url: client_path(@client), confirm: "Tem certeza que deseja apagar este cliente?") if allowed_to?(:destroy?, @client)
        end

        div(class: "grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]") do
          render_details
          render_recent_sales
        end
      end
    end
  end

  private

  def render_details
    render RubyUI::Card.new(class: "min-w-0 p-4 sm:p-6") do
      render Components::DetailList.new(items: [
        [ "Tipo de pessoa", Client.client_types[@client.client_type] ],
        [ "Telefone", @client.phone ],
        [ "Vendas", @sales_count.to_s ],
        [ "Total comprado", number_to_currency(@total_bought) ]
      ])
    end
  end

  def render_recent_sales
    render RubyUI::Card.new(class: "min-w-0") do
      render RubyUI::CardHeader.new(class: "p-4 sm:p-6") do
        render RubyUI::CardTitle.new { "Vendas recentes" }
        render RubyUI::CardDescription.new { "Últimas vendas registradas para este cliente." }
      end
      render RubyUI::CardContent.new(class: "p-4 pt-0 sm:p-6 sm:pt-0") do
        if @recent_sales.empty?
          div(class: "rounded-lg border border-dashed border-gray-200 px-4 py-8 text-center text-sm text-gray-500") do
            "Nenhuma venda registrada para este cliente."
          end
        else
          ul(class: "divide-y divide-gray-100") do
            @recent_sales.each { |sale| render Components::Sales::ListItem.new(sale: sale, title: "Venda ##{sale.id}") }
          end
        end
      end
    end
  end
end

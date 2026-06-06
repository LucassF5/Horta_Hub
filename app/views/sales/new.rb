# frozen_string_literal: true

class Views::Sales::New < Views::Base
  def initialize(sale:, clients:, products:)
    @sale = sale
    @clients = clients
    @products = products
  end

  def view_template
    div(class: "mx-auto bg-background flex flex-col justify-center items-center") do
      div(class: "container mx-auto px-4 py-8") do
        h1(class: "text-3xl font-bold text-gray-800 mb-8") { "Nova Venda" }

        render_errors if @sale.errors.any?
      end

      render Views::Sales::FormComponent.new(
        sale: @sale,
        url: sales_path,
        clients: @clients,
        products: @products
      )
    end
  end

  private

  def render_errors
    render RubyUI::Alert.new(variant: :destructive) do
      div do
        h2(class: "font-bold mb-2") do
          "#{pluralize(@sale.errors.count, 'erro')} impediram a venda de ser salva:"
        end
        ul(class: "list-disc list-inside") do
          @sale.errors.full_messages.each do |message|
            li { message }
          end
        end
      end
    end
  end
end

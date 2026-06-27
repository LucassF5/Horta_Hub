# frozen_string_literal: true

class Views::Sales::FormComponent < Views::Base
  def initialize(sale:, url:, clients:, products:)
    @sale = sale
    @url = url
    @clients = clients
    @products = products
  end

  def view_template
    form_with(
      model: @sale,
      url: @url,
      local: true,
      class: "bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4 w-full max-w-2xl"
    ) do |f|
      render_sale_fields(f)
      render_sale_items(f)
      render_submit(f)
    end
  end

  private

  def render_sale_fields(form)
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "sale_client_id") { "Cliente" }
      form.select(
        :client_id,
        @clients.map { |c| [ c.name, c.id ] },
        { prompt: "Selecione um cliente" },
        id: "sale_client_id",
        class: input_classes
      )
    end

    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "sale_sale_date") { "Data da Venda" }
      form.date_field(
        :sale_date,
        id: "sale_sale_date",
        class: input_classes
      )
    end

    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "sale_status") { "Status" }
      form.select(
        :status,
        [ [ "Pendente", "pending" ], [ "Concluída", "completed" ], [ "Cancelada", "cancelled" ] ],
        {},
        id: "sale_status",
        class: input_classes
      )
    end

    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "sale_notes") { "Observações" }
      form.text_area(
        :notes,
        id: "sale_notes",
        placeholder: "Observações sobre a venda (opcional)",
        rows: 3,
        class: input_classes
      )
    end
  end

  def render_sale_items(form)
    h3(class: "text-lg font-semibold text-gray-800 mb-4 mt-6") { "Itens da Venda" }

    prices_map = @products.each_with_object({}) { |p, h| h[p.id.to_s] = p.price.to_f }

    div(
      data: {
        controller: "sale-item-form",
        sale_item_form_prices_value: prices_map.to_json
      }
    ) do
      div(id: "sale_items") do
        @sale.sale_items.each_with_index do |item, index|
          render Views::Sales::SaleItemFieldsComponent.new(
            item: item,
            products: @products,
            child_index: item.persisted? ? item.id.to_s : index.to_s
          )
        end
      end

      div(class: "flex flex-col gap-3 border-t pt-4 sm:flex-row sm:items-center sm:justify-between") do
        a(
          href: sale_item_fields_sales_path(sale_id: @sale.persisted? ? @sale.id : nil),
          class: "inline-flex h-9 items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-xs hover:bg-accent hover:text-accent-foreground",
          data: { turbo_stream: true }
        ) { "Adicionar item" }

        div(class: "text-right") do
          span(class: "block text-sm text-gray-500") { "Total da venda" }
          span(class: "text-lg font-bold text-gray-900", data: { sale_total: true }) do
            number_to_currency(@sale.total, unit: "R$ ")
          end
        end
      end
    end
  end

  def render_submit(form)
    div(class: "flex items-center justify-between mt-6") do
      render RubyUI::Button.new(type: :submit) { "Salvar Venda" }
    end
  end

  def input_classes
    [
      "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "placeholder:text-muted-foreground",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end

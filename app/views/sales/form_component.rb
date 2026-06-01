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
      form.fields_for :sale_items do |item_form|
        render_item_fields(item_form)
      end
    end
  end

  def render_item_fields(item_form)
    div(class: "border rounded-md p-4 mb-4 bg-gray-50", data: { sale_item: true }) do
      div(class: "grid grid-cols-1 md:grid-cols-3 gap-4") do
        render RubyUI::FormField.new do
          render RubyUI::FormFieldLabel.new { "Produto" }
          item_form.select(
            :product_id,
            @products.map { |p| [ "#{p.name}", p.id ] },
            { prompt: "Selecione um produto" },
            class: input_classes,
            data: { action: "change->sale-item-form#selectProduct" }
          )
        end

        render RubyUI::FormField.new do
          render RubyUI::FormFieldLabel.new { "Quantidade" }
          item_form.number_field(
            :quantity,
            min: 1,
            placeholder: "Qtd",
            class: input_classes
          )
        end

        render RubyUI::FormField.new do
          render RubyUI::FormFieldLabel.new { "Preço Unitário" }

          current_price = item_form.object&.unit_price
          display_text = current_price ? "R$ #{"%.2f" % current_price}" : "R$ —"

          span(class: "text-sm font-medium text-gray-700 py-1", data: { price_display: true }) { display_text }

          item_form.hidden_field(:unit_price, data: { price_field: true })
        end
      end

      if item_form.object&.persisted?
        div(class: "mt-2") do
          item_form.hidden_field :id
          item_form.label :_destroy, class: "flex items-center gap-2 text-sm text-red-600 cursor-pointer" do
            item_form.check_box :_destroy, class: "rounded border-gray-300"
            plain "Remover este item"
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

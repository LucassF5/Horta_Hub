# frozen_string_literal: true

class Views::Sales::SaleItemFieldsComponent < Views::Base
  def initialize(item:, products:, child_index:)
    @item = item
    @products = products
    @child_index = child_index
  end

  def view_template
    div(class: "rounded-md border bg-gray-50 p-3 sm:p-4", data: { sale_item: true }) do
      render_hidden_fields

      # No celular o produto ocupa a linha toda; quantidade e preço dividem a seguinte.
      div(class: "grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-[minmax(0,2fr)_minmax(0,1fr)_minmax(0,1.5fr)]") do
        div(class: "col-span-2 min-w-0 md:col-span-1") { render_product_field }
        div(class: "min-w-0") { render_quantity_field }
        div(class: "min-w-0") { render_unit_price_field }
      end

      div(class: "mt-3 flex items-center justify-between gap-3 border-t pt-3") do
        render_subtotal
        button(
          type: "button",
          class: "text-sm font-medium text-red-600 hover:text-red-700",
          data: { action: "sale-item-form#removeItem" }
        ) { "Remover item" }
      end
    end
  end

  private

  def render_hidden_fields
    input(type: "hidden", name: field_name(:id), value: @item.id.to_s) if @item.persisted?
    input(type: "hidden", name: field_name(:_destroy), value: "0", data: { destroy_field: true })
  end

  def render_product_field
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: field_id(:product_id)) { "Produto" }
      select(
        id: field_id(:product_id),
        name: field_name(:product_id),
        class: input_classes,
        data: { action: "change->sale-item-form#selectProduct" }
      ) do
        option(value: "") { "Selecione um produto" }
        @products.each do |product|
          option(value: product.id.to_s, selected: product.id == @item.product_id) { product.name }
        end
      end
    end
  end

  def render_quantity_field
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: field_id(:quantity)) { "Quantidade" }
      input(
        type: "number",
        id: field_id(:quantity),
        name: field_name(:quantity),
        min: 1,
        value: (@item.quantity || 1).to_s,
        placeholder: "Qtd",
        class: input_classes,
        data: { action: "input->sale-item-form#recalculate change->sale-item-form#recalculate", quantity_field: true }
      )
    end
  end

  def render_unit_price_field
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: field_id(:unit_price)) { "Preço Unitário" }

      current_price = @item.unit_price
      display_text = current_price.present? ? number_to_currency(current_price, unit: "R$ ") : "R$ -"
      custom_price = @item.custom_price?

      span(class: "block text-sm font-medium text-gray-700 py-2", hidden: custom_price, data: { price_display: true }) { display_text }
      input(
        type: "number",
        id: field_id(:unit_price),
        name: field_name(:unit_price),
        min: 0.01,
        step: 0.01,
        value: decimal_value(current_price),
        placeholder: "R$ 0,00",
        hidden: !custom_price,
        disabled: !custom_price,
        class: input_classes,
        data: { action: "input->sale-item-form#recalculate change->sale-item-form#recalculate", price_field: true }
      )

      render_custom_price_toggle(custom_price)
    end
  end

  def render_custom_price_toggle(custom_price)
    label(for: field_id(:custom_price), class: "mt-2 flex items-center gap-2 text-xs text-gray-700 sm:text-sm") do
      input(type: "hidden", name: field_name(:custom_price), value: "0")
      input(
        type: "checkbox",
        id: field_id(:custom_price),
        name: field_name(:custom_price),
        value: "1",
        checked: custom_price,
        class: "h-4 w-4 rounded border-border",
        data: { action: "change->sale-item-form#toggleCustomPrice", custom_price_toggle: true }
      )
      plain "Preço personalizado"
    end
  end

  def render_subtotal
    subtotal = (@item.quantity || 0) * (@item.unit_price || 0)

    p(class: "text-sm text-gray-600") do
      plain "Subtotal "
      span(class: "font-semibold tabular-nums text-gray-900", data: { subtotal_display: true }) { number_to_currency(subtotal, unit: "R$ ") }
    end
  end

  def field_name(attribute)
    "sale[sale_items_attributes][#{@child_index}][#{attribute}]"
  end

  def field_id(attribute)
    "sale_sale_items_attributes_#{@child_index}_#{attribute}"
  end

  def decimal_value(value)
    value&.to_d&.to_s("F")
  end

  def input_classes
    [
      "flex h-10 w-full min-w-0 rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "placeholder:text-muted-foreground",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end

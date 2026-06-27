# frozen_string_literal: true

class Views::Sales::SaleItemFieldsComponent < Views::Base
  def initialize(item:, products:, child_index:)
    @item = item
    @products = products
    @child_index = child_index
  end

  def view_template
    div(class: "border rounded-md p-4 mb-4 bg-gray-50", data: { sale_item: true }) do
      render_hidden_fields

      div(class: "grid grid-cols-1 md:grid-cols-4 gap-4") do
        render_product_field
        render_quantity_field
        render_unit_price_field
        render_subtotal_field
      end

      div(class: "mt-3 flex justify-end") do
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
    input(type: "hidden", name: field_name(:id), value: @item.id) if @item.persisted?
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
          option(value: product.id, selected: product.id == @item.product_id) { product.name }
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
        value: @item.quantity || 1,
        placeholder: "Qtd",
        class: input_classes,
        data: { action: "input->sale-item-form#quantityChanged change->sale-item-form#quantityChanged", quantity_field: true }
      )
    end
  end

  def render_unit_price_field
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: field_id(:unit_price)) { "Preço Unitário" }

      current_price = @item.unit_price
      display_text = current_price.present? ? number_to_currency(current_price, unit: "R$ ") : "R$ -"

      span(class: "block text-sm font-medium text-gray-700 py-2", data: { price_display: true }) { display_text }
      input(type: "hidden", id: field_id(:unit_price), name: field_name(:unit_price), value: current_price, data: { price_field: true })
    end
  end

  def render_subtotal_field
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new { "Subtotal" }

      subtotal = (@item.quantity || 0) * (@item.unit_price || 0)
      span(class: "block text-sm font-semibold text-gray-800 py-2", data: { subtotal_display: true }) do
        number_to_currency(subtotal, unit: "R$ ")
      end
    end
  end

  def field_name(attribute)
    "sale[sale_items_attributes][#{@child_index}][#{attribute}]"
  end

  def field_id(attribute)
    "sale_sale_items_attributes_#{@child_index}_#{attribute}"
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

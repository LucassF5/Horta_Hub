# frozen_string_literal: true

class Views::Products::FormComponent < Views::Base
  def initialize(product:, url:, cancel_href:)
    @product = product
    @url = url
    @cancel_href = cancel_href
  end

  def view_template
    form_with(model: @product, url: @url, local: true) do |f|
      render Components::Forms::Card.new(submit_label: "Salvar produto", cancel_href: @cancel_href) do
        render_form_fields(f)
      end
    end
  end

  private

  def render_form_fields(form)
    div(class: "grid gap-5 sm:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]") do
      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "product_name") { "Nome" }
        form.text_field(
          :name,
          id: "product_name",
          placeholder: "Ex.: Alface crespa",
          class: input_classes
        )
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "product_price") { "Preço padrão (R$)" }
        form.number_field(
          :price,
          id: "product_price",
          value: (Kernel.format("%.2f", @product.price) if @product.price),
          placeholder: "0,00",
          step: 0.01,
          min: 0.01,
          inputmode: "decimal",
          class: input_classes
        )
        p(class: "text-xs text-gray-500") { "Usado ao adicionar o produto em uma venda; pode ser alterado no item." }
      end
    end
  end

  def input_classes
    [
      "flex h-10 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "placeholder:text-muted-foreground",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end

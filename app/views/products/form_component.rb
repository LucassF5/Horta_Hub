# frozen_string_literal: true

class Views::Products::FormComponent < Views::Base
  def initialize(product:, url:)
    @product = product
    @url = url
  end

  def view_template
    form_with(
      model: @product,
      url: @url,
      local: true,
      class: "bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4 w-full max-w-lg"
    ) do |f|
      render_form_fields(f)
    end
  end

  private

  def render_form_fields(form)
    # Campo Nome
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "product_name") { "Nome" }
      form.text_field(
        :name,
        id: "product_name",
        placeholder: "Nome do produto",
        class: input_classes
      )
    end

    # Campo Preço
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "product_price") { "Preço" }
      form.number_field(
        :price,
        id: "product_price",
        placeholder: "$ 3",
        step: 0.01,
        class: input_classes
      )
    end

    # Botão Submit
    div(class: "flex items-center justify-between") do
      render RubyUI::Button.new(type: :submit) { "Salvar produto" }
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

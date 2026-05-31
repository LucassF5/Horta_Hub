# frozen_string_literal: true

class Views::Clients::FormComponent < Views::Base
  def initialize(client:, url:)
    @client = client
    @url = url
  end

  def view_template
    form_with(
      model: @client,
      url: @url,
      local: true,
      class: "bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4 w-full max-w-lg"
    ) do |f|
      render_form_fields(f)
    end
  end

  private

  def render_form_fields(form)
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "client_name") { "Nome" }
      form.text_field(
        :name,
        id: "client_name",
        placeholder: "Nome do cliente",
        class: input_classes
      )
    end

    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "client_phone") { "Telefone" }
      form.telephone_field(
        :phone,
        id: "client_phone",
        placeholder: "Telefone",
        class: input_classes
      )
    end

    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "client_client_type") { "Tipo de pessoa" }
      form.select(
        :client_type,
        Client.client_types.keys.map { |key| [ Client.client_types[key], key ] },
        {},
        id: "client_client_type",
        class: input_classes
      )
    end

    div(class: "flex items-center justify-between") do
      render RubyUI::Button.new(type: :submit) { "Salvar cliente" }
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

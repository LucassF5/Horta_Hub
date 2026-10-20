# frozen_string_literal: true

# Moldura dos formulários de cadastro: campos no corpo e ações fixas no rodapé.
class Components::Forms::Card < Components::Base
  def initialize(submit_label:, cancel_href:)
    @submit_label = submit_label
    @cancel_href = cancel_href
  end

  def view_template(&fields)
    div(class: "rounded-lg border bg-white") do
      div(class: "space-y-5 p-4 sm:p-6", &fields)

      div(class: "flex flex-col-reverse gap-2 border-t px-4 py-3 sm:flex-row sm:justify-end sm:px-6") do
        render RubyUI::Link.new(href: @cancel_href, variant: :outline) { "Cancelar" }
        render RubyUI::Button.new(type: :submit) { @submit_label }
      end
    end
  end
end

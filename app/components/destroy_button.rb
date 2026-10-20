# frozen_string_literal: true

# Botão "Apagar" das páginas de detalhe, com confirmação antes do envio.
class Components::DestroyButton < Components::Base
  def initialize(url:, confirm:)
    @url = url
    @confirm = confirm
  end

  def view_template
    form_with(url: @url, method: :delete, local: true, class: "inline-flex") do
      render RubyUI::Button.new(
        type: :submit,
        variant: :outline,
        class: "text-destructive hover:bg-destructive/10 hover:text-destructive",
        data: { turbo_confirm: @confirm }
      ) { "Apagar" }
    end
  end
end

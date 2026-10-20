# frozen_string_literal: true

class Views::Passwords::Edit < Views::Base
  def initialize(token:)
    @token = token
  end

  def view_template
    div(class: "mb-8") do
      h1(class: "text-3xl font-semibold tracking-tight text-gray-900") { "Atualize sua senha" }
      p(class: "mt-2 text-sm text-gray-600") { "Escolha uma nova senha. Por segurança, as sessões abertas em outros aparelhos serão encerradas." }
    end

    form_with(url: password_path(@token), method: :put, class: "space-y-5") do
      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "password") { "Nova senha" }
        render RubyUI::Input.new(type: :password, id: "password", name: "password", required: true, autocomplete: "new-password", maxlength: 72, class: "h-10")
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "password_confirmation") { "Confirme a nova senha" }
        render RubyUI::Input.new(type: :password, id: "password_confirmation", name: "password_confirmation", required: true, autocomplete: "new-password", maxlength: 72, class: "h-10")
      end

      render RubyUI::Button.new(type: :submit, size: :lg, class: "w-full") { "Salvar" }
    end
  end
end

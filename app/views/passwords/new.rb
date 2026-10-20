# frozen_string_literal: true

class Views::Passwords::New < Views::Base
  def initialize(params: {})
    @params = params
  end

  def view_template
    div(class: "mb-8") do
      h1(class: "text-3xl font-semibold tracking-tight text-gray-900") { "Esqueceu sua senha?" }
      p(class: "mt-2 text-sm text-gray-600") { "Informe o e-mail da sua conta e enviaremos um link para criar uma nova senha." }
    end

    form_with(url: passwords_path, class: "space-y-5") do
      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "email_address") { "E-mail" }
        render RubyUI::Input.new(
          type: :email,
          id: "email_address",
          name: "email_address",
          required: true,
          autofocus: true,
          autocomplete: "username",
          placeholder: "voce@exemplo.com",
          value: @params[:email_address],
          class: "h-10"
        )
      end

      render RubyUI::Button.new(type: :submit, size: :lg, class: "w-full") { "Enviar instruções de redefinição" }
    end

    p(class: "mt-8 border-t pt-6 text-center text-sm text-gray-600") do
      plain "Lembrou a senha? "
      a(href: new_session_path, class: "font-medium text-gray-900 underline underline-offset-4 hover:no-underline") { "Voltar para o login" }
    end
  end
end

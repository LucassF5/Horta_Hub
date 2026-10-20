# frozen_string_literal: true

class Views::Sessions::New < Views::Base
  def initialize(params: {})
    @params = params
  end

  def view_template
    div(class: "mb-8") do
      h1(class: "text-3xl font-semibold tracking-tight text-gray-900") { "Entrar" }
      p(class: "mt-2 text-sm text-gray-600") { "Acesse a organização da sua horta com seu e-mail e senha." }
    end

    form_with(url: session_url, class: "space-y-5") do
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

      render RubyUI::FormField.new do
        div(class: "flex items-center justify-between") do
          render RubyUI::FormFieldLabel.new(for: "password") { "Senha" }
          a(href: new_password_path, class: "text-sm font-medium text-gray-600 underline-offset-4 hover:text-gray-900 hover:underline") { "Esqueceu a senha?" }
        end
        render RubyUI::Input.new(
          type: :password,
          id: "password",
          name: "password",
          required: true,
          autocomplete: "current-password",
          maxlength: 72,
          class: "h-10"
        )
      end

      render RubyUI::Button.new(type: :submit, size: :lg, class: "w-full") { "Entrar" }
    end

    div(class: "mt-10 border-t pt-6") do
      p(class: "text-sm font-medium text-gray-900") { "Ainda não usa o Horta Hub?" }
      p(class: "mt-1 text-sm text-gray-600") { "Crie a organização da sua horta e a conta de quem vai administrá-la." }
      render RubyUI::Link.new(href: new_organization_path, variant: :outline, size: :lg, class: "mt-4 w-full") { "Criar organização" }
    end
  end
end

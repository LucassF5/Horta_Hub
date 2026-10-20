# frozen_string_literal: true

class Views::Organizations::New < Views::Base
  def initialize(organization:, user:)
    @organization = organization
    @user = user
  end

  def view_template
    div(class: "mb-8") do
      h1(class: "text-3xl font-semibold tracking-tight text-gray-900") { "Criar organização" }
      p(class: "mt-2 text-sm text-gray-600") do
        "Cadastre sua horta e a conta de quem vai administrá-la. Ao terminar, você já entra no painel."
      end
    end

    render_errors if @organization.errors.any? || @user.errors.any?

    form_with(url: organizations_path, method: :post, class: "space-y-8") do
      render_organization_fields
      render_user_fields

      render RubyUI::Button.new(type: :submit, size: :lg, class: "w-full") { "Criar organização" }
    end

    p(class: "mt-8 border-t pt-6 text-center text-sm text-gray-600") do
      plain "Já tem uma conta? "
      a(href: new_session_path, class: "font-medium text-gray-900 underline underline-offset-4 hover:no-underline") { "Entrar" }
    end
  end

  private

  def render_errors
    render RubyUI::Alert.new(variant: :destructive, class: "mb-6") do
      div do
        h2(class: "font-bold mb-2") { "Corrija os erros abaixo:" }
        ul(class: "list-disc list-inside") do
          @organization.errors.full_messages.each { |msg| li { msg } }
          @user.errors.full_messages.each { |msg| li { msg } }
        end
      end
    end
  end

  def render_organization_fields
    fieldset(class: "space-y-4") do
      render_legend("Organização", "O nome que sua equipe e seus clientes reconhecem.")

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "organization_name") { "Nome da organização" }
        render RubyUI::Input.new(
          id: "organization_name",
          name: "organization[name]",
          value: @organization.name,
          required: true,
          autofocus: true,
          autocomplete: "organization",
          placeholder: "Ex.: Horta do João",
          class: "h-10"
        )
      end
    end
  end

  def render_user_fields
    fieldset(class: "space-y-4") do
      render_legend("Sua conta", "Você será o proprietário da organização, com acesso a todas as ações.")

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "user_username") { "Nome de usuário" }
        render RubyUI::Input.new(
          id: "user_username",
          name: "user[username]",
          value: @user.username,
          required: true,
          autocomplete: "username",
          placeholder: "Ex.: joao_silva",
          class: "h-10"
        )
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "user_email_address") { "E-mail" }
        render RubyUI::Input.new(
          type: :email,
          id: "user_email_address",
          name: "user[email_address]",
          value: @user.email_address,
          required: true,
          autocomplete: "email",
          placeholder: "voce@exemplo.com",
          class: "h-10"
        )
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "user_password") { "Senha" }
        render RubyUI::Input.new(
          type: :password,
          id: "user_password",
          name: "user[password]",
          required: true,
          autocomplete: "new-password",
          maxlength: 72,
          class: "h-10"
        )
      end
    end
  end

  def render_legend(title, description)
    legend(class: "w-full") do
      span(class: "block text-base font-semibold text-gray-900") { title }
      span(class: "mt-1 block text-sm text-gray-600") { description }
    end
  end
end

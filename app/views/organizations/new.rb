# frozen_string_literal: true

class Views::Organizations::New < Views::Base
  def initialize(organization:, user:)
    @organization = organization
    @user = user
  end

  def view_template
    div(class: "mx-auto md:w-2/3 w-full") do
      h1(class: "font-bold text-4xl mb-2") { "Criar Organização" }
      p(class: "text-gray-600 mb-8") { "Crie sua organização e conta de administrador para começar." }

      render_errors if @organization.errors.any? || @user.errors.any?

      form_with(url: organizations_path, method: :post, class: "contents") do |form|
        render_organization_fields(form)
        render_user_fields(form)

        div(class: "flex items-center justify-between") do
          render RubyUI::Button.new(type: :submit) { "Criar Organização" }
        end
      end

      div(class: "mt-6 pt-6 border-t border-gray-300") do
        p(class: "text-sm text-gray-500") do
          plain "Já tem uma conta? "
          a(href: new_session_path, class: "text-blue-600 underline hover:no-underline") { "Fazer login" }
        end
      end
    end
  end

  private

  def render_errors
    render RubyUI::Alert.new(variant: :destructive) do
      div do
        h2(class: "font-bold mb-2") { "Corrija os erros abaixo:" }
        ul(class: "list-disc list-inside") do
          @organization.errors.full_messages.each { |msg| li { msg } }
          @user.errors.full_messages.each { |msg| li { msg } }
        end
      end
    end
  end

  def render_organization_fields(form)
    fieldset(class: "mb-8") do
      legend(class: "text-lg font-semibold text-gray-800 mb-4 pb-2 border-b border-gray-200") { "Dados da Organização" }

      render RubyUI::FormField.new(class: "my-4") do
        render RubyUI::FormFieldLabel.new { "Nome da Organização" }
        form.text_field(
          "organization[name]",
          value: @organization.name,
          required: true,
          autofocus: true,
          placeholder: "Ex: Horta do João",
          class: input_classes
        )
      end
    end
  end

  def render_user_fields(form)
    fieldset(class: "mb-8") do
      legend(class: "text-lg font-semibold text-gray-800 mb-4 pb-2 border-b border-gray-200") { "Sua Conta (Administrador)" }

      render RubyUI::FormField.new(class: "my-4") do
        render RubyUI::FormFieldLabel.new { "Nome de usuário" }
        form.text_field(
          "user[username]",
          value: @user.username,
          required: true,
          placeholder: "Ex: joao_silva",
          class: input_classes
        )
      end

      render RubyUI::FormField.new(class: "my-4") do
        render RubyUI::FormFieldLabel.new { "Email" }
        form.email_field(
          "user[email_address]",
          value: @user.email_address,
          required: true,
          autocomplete: "email",
          placeholder: "seu@email.com",
          class: input_classes
        )
      end

      render RubyUI::FormField.new(class: "my-4") do
        render RubyUI::FormFieldLabel.new { "Senha" }
        form.password_field(
          "user[password]",
          required: true,
          autocomplete: "new-password",
          placeholder: "Mínimo 6 caracteres",
          class: input_classes
        )
      end
    end
  end

  def input_classes
    "block shadow-sm rounded-md border border-gray-400 focus:outline-blue-600 px-3 py-2 mt-2 w-full"
  end
end

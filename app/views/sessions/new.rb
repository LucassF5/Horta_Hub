# frozen_string_literal: true

class Views::Sessions::New < Views::Base
  def initialize(params: {})
    @params = params
  end

  def view_template
    div(class: "mx-auto md:w-2/3 w-full") do
      h1(class: "font-bold text-4xl") { "Sign in" }

      form_with(url: helpers.session_url, class: "contents") do |form|
        div(class: "my-5") do
          form.email_field(
            :email_address,
            required: true,
            autofocus: true,
            autocomplete: "username",
            placeholder: "Digite seu email",
            value: @params[:email_address],
            class: input_classes
          )
        end

        div(class: "my-5") do
          form.password_field(
            :password,
            required: true,
            autocomplete: "current-password",
            placeholder: "Digite sua senha",
            maxlength: 72,
            class: input_classes
          )
        end

        div(class: "col-span-6 sm:flex sm:items-center sm:gap-4") do
          div(class: "inline") do
            render RubyUI::Button.new(type: :submit) { "Entrar" }
          end

          div(class: "mt-4 text-sm text-gray-500 sm:mt-0") do
            a(href: helpers.new_password_path, class: "text-gray-700 underline hover:no-underline") { "Esqueceu a senha?" }
          end
        end

        div(class: "mt-6 pt-6 border-t border-gray-300 col-span-6 sm:flex sm:items-center sm:gap-4") do
          h2 { "Não tem uma conta?" }
          div(class: "mt-4 text-sm text-gray-500 sm:mt-0") do
            render RubyUI::Link.new(href: helpers.new_organization_path, variant: :primary) { "Criar Organização" }
          end
        end
      end
    end
  end

  private

  def input_classes
    "block shadow-sm rounded-md border border-gray-400 focus:outline-blue-600 px-3 py-2 mt-2 w-full"
  end
end

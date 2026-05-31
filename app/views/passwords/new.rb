# frozen_string_literal: true

class Views::Passwords::New < Views::Base
  def initialize(params: {})
    @params = params
  end

  def view_template
    div(class: "mx-auto md:w-2/3 w-full") do
      h1(class: "font-bold text-4xl") { "Esqueceu sua senha?" }

      form_with(url: helpers.passwords_path, class: "contents") do |form|
        div(class: "my-5") do
          form.email_field(
            :email_address,
            required: true,
            autofocus: true,
            autocomplete: "username",
            placeholder: "Digite seu email",
            value: @params[:email_address],
            class: "block shadow-sm rounded-md border border-gray-400 focus:outline-blue-600 px-3 py-2 mt-2 w-full"
          )
        end

        div(class: "inline") do
          render RubyUI::Button.new(type: :submit) { "Enviar instruções de redefinição" }
        end
      end
    end
  end
end

# frozen_string_literal: true

class Views::Passwords::Edit < Views::Base
  def initialize(token:)
    @token = token
  end

  def view_template
    div(class: "mx-auto md:w-2/3 w-full") do
      h1(class: "font-bold text-4xl") { "Atualize sua senha" }

      form_with(url: helpers.password_path(@token), method: :put, class: "contents") do |form|
        div(class: "my-5") do
          form.password_field(
            :password,
            required: true,
            autocomplete: "new-password",
            placeholder: "Nova senha",
            maxlength: 72,
            class: input_classes
          )
        end

        div(class: "my-5") do
          form.password_field(
            :password_confirmation,
            required: true,
            autocomplete: "new-password",
            placeholder: "Confirme a nova senha",
            maxlength: 72,
            class: input_classes
          )
        end

        div(class: "inline") do
          render RubyUI::Button.new(type: :submit) { "Salvar" }
        end
      end
    end
  end

  private

  def input_classes
    "block shadow-sm rounded-md border border-gray-400 focus:outline-blue-600 px-3 py-2 mt-2 w-full"
  end
end

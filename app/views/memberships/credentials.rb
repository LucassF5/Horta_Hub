# frozen_string_literal: true

# Mostra a senha gerada uma única vez. A senha nunca passa pelo flash.
class Views::Memberships::Credentials < Views::Base
  def initialize(membership:, password:, notice:)
    @membership = membership
    @password = password
    @notice = notice
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      render Components::FlashMessages.new(messages: { notice: @notice })

      h1(class: "text-3xl font-bold text-gray-800 mb-6") { "Credenciais do funcionário" }

      div(class: "bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4 w-full max-w-lg space-y-4") do
        render_detail("Nome de usuário", @membership.user.username)
        render_detail("E-mail", @membership.user.email_address)
        render_password_field

        render RubyUI::Alert.new(variant: :warning) do
          plain "Esta senha não será mostrada novamente. Copie e repasse ao funcionário."
        end

        render RubyUI::Link.new(href: memberships_path, variant: :outline) { "Voltar para funcionários" }
      end
    end
  end

  private

  def render_detail(label, value)
    div do
      p(class: "text-sm font-medium text-gray-600") { label }
      p(class: "text-base") { value }
    end
  end

  def render_password_field
    div(data: { controller: "clipboard" }) do
      label(for: "generated_password", class: "text-sm font-medium text-gray-600") { "Senha" }
      div(class: "mt-1 flex gap-2") do
        input(
          type: "text",
          id: "generated_password",
          value: @password,
          readonly: true,
          class: "flex h-9 w-full rounded-md border border-border bg-background px-3 py-1 font-mono text-sm shadow-xs",
          data: { clipboard_target: "source" }
        )
        render RubyUI::Button.new(type: :button, variant: :outline, data: { action: "clipboard#copy" }) { "Copiar senha" }
      end
    end
  end
end

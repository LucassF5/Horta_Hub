# frozen_string_literal: true

# Mostra a senha gerada uma única vez. A senha nunca passa pelo flash.
class Views::Memberships::Credentials < Views::Base
  def initialize(membership:, password:, notice:)
    @membership = membership
    @password = password
    @notice = notice
  end

  def view_template
    # turbo_temporary: o Turbo não guarda esta página no cache de snapshots,
    # então voltar no histórico não mostra a senha de novo.
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8", data: { turbo_temporary: true }) do
      div(class: "max-w-2xl") do
        render Components::FlashMessages.new(messages: { notice: @notice })

        render Components::PageHeader.new(
          title: "Credenciais do funcionário",
          description: "Repasse estes dados ao funcionário para o primeiro acesso.",
          back: [ "Voltar para funcionários", memberships_path ]
        )

        render RubyUI::Card.new(class: "space-y-5 p-4 sm:p-6") do
          render Components::DetailList.new(items: [
            [ "Nome de usuário", @membership.user.username ],
            [ "E-mail", @membership.user.email_address ]
          ])
          render_password_field

          render RubyUI::Alert.new(variant: :warning) do
            plain "Esta senha não será mostrada novamente. Copie e repasse ao funcionário."
          end
        end
      end
    end
  end

  private

  def render_password_field
    div(data: { controller: "clipboard" }) do
      label(for: "generated_password", class: "text-sm text-gray-500") { "Senha" }
      div(class: "mt-1 flex flex-col gap-2 sm:flex-row") do
        input(
          type: "text",
          id: "generated_password",
          value: @password,
          readonly: true,
          class: "flex h-10 w-full rounded-md border border-border bg-background px-3 py-1 font-mono text-base tracking-wider shadow-xs",
          data: { clipboard_target: "source" }
        )
        render RubyUI::Button.new(type: :button, variant: :outline, class: "shrink-0", data: { action: "clipboard#copy" }) do
          render PhlexIcons::Lucide::Copy.new(class: "size-4", aria: { hidden: true })
          span { "Copiar senha" }
        end
      end
    end
  end
end

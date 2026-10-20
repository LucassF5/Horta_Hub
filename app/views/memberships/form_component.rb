# frozen_string_literal: true

class Views::Memberships::FormComponent < Views::Base
  def initialize(creation:, url:, cancel_href:)
    @creation = creation
    @url = url
    @cancel_href = cancel_href
  end

  def view_template
    # Sem Turbo: a resposta 200 com a senha gerada precisa ser renderizada.
    form_with(model: @creation, url: @url, local: true, data: { turbo: false }) do |f|
      render Components::Forms::Card.new(submit_label: "Adicionar funcionário", cancel_href: @cancel_href) do
        render_form_fields(f)
      end
    end
  end

  private

  def render_form_fields(form)
    div(class: "grid gap-5 sm:grid-cols-2") do
      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "member_username") { "Nome de usuário" }
        form.text_field(
          :username,
          id: "member_username",
          placeholder: "Ex.: maria.silva",
          autocomplete: "off",
          class: input_classes
        )
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "member_email_address") { "E-mail" }
        form.email_field(
          :email_address,
          id: "member_email_address",
          placeholder: "nome@exemplo.com",
          autocomplete: "off",
          class: input_classes
        )
      end
    end

    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "member_role") { "Cargo" }
      form.select(
        :role,
        Current.membership.assignable_roles.map { |role| [ Membership.role_label(role), role ] },
        {},
        id: "member_role",
        class: input_classes
      )
      render RubyUI::FormFieldHint.new { "Se o e-mail já tiver conta, a pessoa entra na organização com a senha que já usa." }
    end
  end

  def input_classes
    [
      "flex h-10 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "placeholder:text-muted-foreground",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end

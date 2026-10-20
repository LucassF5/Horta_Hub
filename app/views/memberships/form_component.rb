# frozen_string_literal: true

class Views::Memberships::FormComponent < Views::Base
  def initialize(creation:, url:)
    @creation = creation
    @url = url
  end

  def view_template
    # Sem Turbo: a resposta 200 com a senha gerada precisa ser renderizada.
    form_with(
      model: @creation,
      url: @url,
      local: true,
      data: { turbo: false },
      class: "bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4 w-full max-w-lg"
    ) do |f|
      render_form_fields(f)
    end
  end

  private

  def render_form_fields(form)
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "member_username") { "Nome de usuário" }
      form.text_field(
        :username,
        id: "member_username",
        placeholder: "Nome de usuário",
        class: input_classes
      )
    end

    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "member_email_address") { "E-mail" }
      form.email_field(
        :email_address,
        id: "member_email_address",
        placeholder: "E-mail",
        class: input_classes
      )
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
    end

    div(class: "flex items-center justify-between") do
      render RubyUI::Button.new(type: :submit) { "Adicionar funcionário" }
    end
  end

  def input_classes
    [
      "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "placeholder:text-muted-foreground",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end

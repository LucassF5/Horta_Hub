# frozen_string_literal: true

class Views::Memberships::Edit < Views::Base
  def initialize(membership:)
    @membership = membership
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div(class: "max-w-2xl") do
        render Components::PageHeader.new(
          title: "Editar funcionário",
          description: "#{@membership.user.username} · #{@membership.user.email_address}",
          back: [ "Voltar para funcionários", memberships_path ]
        )
        render Components::Forms::Errors.new(record: @membership, subject: "o cargo")
        render_form
      end
    end
  end

  private

  def render_form
    form_with(model: @membership, scope: :membership, url: membership_path(@membership), local: true) do |form|
      render Components::Forms::Card.new(submit_label: "Salvar cargo", cancel_href: memberships_path) do
        render RubyUI::FormField.new do
          render RubyUI::FormFieldLabel.new(for: "membership_role") { "Cargo" }
          form.select(
            :role,
            Current.membership.assignable_roles.map { |role| [ Membership.role_label(role), role ] },
            {},
            id: "membership_role",
            class: input_classes
          )
        end
      end
    end
  end

  def input_classes
    [
      "flex h-10 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end

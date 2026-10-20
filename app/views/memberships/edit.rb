# frozen_string_literal: true

class Views::Memberships::Edit < Views::Base
  def initialize(membership:)
    @membership = membership
  end

  def view_template
    div(class: "mx-auto bg-background flex flex-col justify-center items-center") do
      div(class: "container mx-auto px-4 py-8") do
        h1(class: "text-3xl font-bold text-gray-800 mb-8") { "Editar funcionário" }

        render_errors if @membership.errors.any?
      end

      render_form
    end
  end

  private

  def render_form
    form_with(
      model: @membership,
      scope: :membership,
      url: membership_path(@membership),
      local: true,
      class: "bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4 w-full max-w-lg"
    ) do |form|
      div(class: "mb-4") do
        p(class: "text-sm font-medium text-gray-600") { "Nome de usuário" }
        p(class: "text-base") { @membership.user.username }
      end

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

      div(class: "flex items-center justify-between") do
        render RubyUI::Button.new(type: :submit) { "Salvar cargo" }
        render RubyUI::Link.new(href: memberships_path, variant: :outline) { "Cancelar" }
      end
    end
  end

  def render_errors
    render RubyUI::Alert.new(variant: :destructive) do
      div do
        h2(class: "font-bold mb-2") do
          "#{pluralize(@membership.errors.count, 'erro')} impediram o cargo de ser salvo:"
        end
        ul(class: "list-disc list-inside") do
          @membership.errors.full_messages.each do |message|
            li { message }
          end
        end
      end
    end
  end

  def input_classes
    [
      "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end

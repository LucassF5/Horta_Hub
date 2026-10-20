# frozen_string_literal: true

# Ações compactas (ver, editar, apagar) de um registro, exibidas conforme a policy.
class Components::Listings::RowActions < Components::Base
  ICON_CLASSES = "size-4"

  def initialize(record:, show_path:, edit_path:, destroy_path:, confirm:)
    @record = record
    @show_path = show_path
    @edit_path = edit_path
    @destroy_path = destroy_path
    @confirm = confirm
  end

  def view_template
    div(class: "flex items-center justify-end gap-0.5 sm:gap-1") do
      action_link(@show_path, "Ver", PhlexIcons::Lucide::Eye)
      action_link(@edit_path, "Editar", PhlexIcons::Lucide::Pencil) if allowed_to?(:edit?, @record)
      render_destroy if allowed_to?(:destroy?, @record)
    end
  end

  private

  def action_link(href, label, icon)
    render RubyUI::Link.new(href: href, variant: :ghost, icon: true, title: label, class: "size-8 sm:size-9", data: { turbo_frame: "_top" }) do
      render icon.new(class: ICON_CLASSES, aria: { hidden: true })
      span(class: "sr-only") { label }
    end
  end

  def render_destroy
    form_with(url: @destroy_path, method: :delete, local: true, class: "inline-flex", data: { turbo_frame: "_top" }) do
      render RubyUI::Button.new(
        type: :submit,
        variant: :ghost,
        icon: true,
        title: "Apagar",
        class: "size-8 text-destructive hover:bg-destructive/10 hover:text-destructive sm:size-9",
        data: { turbo_confirm: @confirm }
      ) do
        render PhlexIcons::Lucide::Trash2.new(class: ICON_CLASSES, aria: { hidden: true })
        span(class: "sr-only") { "Apagar" }
      end
    end
  end
end

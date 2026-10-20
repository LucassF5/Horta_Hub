# frozen_string_literal: true

class Views::Memberships::Index < Views::Base
  def initialize(memberships:)
    @memberships = memberships
  end

  def view_template
    div(class: "grow") do
      div(class: "container mx-auto px-4 py-8") do
        render_header
        render_table
      end
    end
  end

  private

  def render_header
    div(class: "flex justify-between items-center mb-6") do
      h1(class: "text-3xl font-bold text-gray-800") { "Funcionários" }
      render RubyUI::Link.new(href: new_membership_path, variant: :primary) { "Novo funcionário" } if allowed_to?(:index?, Membership)
    end
  end

  def render_table
    render RubyUI::Table.new do
      render RubyUI::TableHeader.new do
        render RubyUI::TableRow.new do
          render RubyUI::TableHead.new { "Nome de usuário" }
          render RubyUI::TableHead.new { "E-mail" }
          render RubyUI::TableHead.new { "Cargo" }
          render RubyUI::TableHead.new(class: "text-right") { "Ações" }
        end
      end

      render RubyUI::TableBody.new do
        @memberships.each { |membership| render_membership_row(membership) }
      end
    end
  end

  def render_membership_row(membership)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new { membership.user.username }
      render RubyUI::TableCell.new { membership.user.email_address }
      render RubyUI::TableCell.new { membership.role_label }
      render RubyUI::TableCell.new(class: "text-right") do
        div(class: "flex justify-end items-center gap-2") { render_membership_actions(membership) }
      end
    end
  end

  def render_membership_actions(membership)
    render RubyUI::Link.new(href: edit_membership_path(membership), variant: :primary) { "Editar" } if allowed_to?(:edit?, membership)

    if allowed_to?(:reset_password?, membership)
      # Sem Turbo: a resposta 200 com a nova senha precisa ser renderizada.
      # Por isso não há turbo_confirm aqui, ele não roda com Turbo desligado.
      form_with(
        url: reset_password_membership_path(membership),
        method: :post,
        local: true,
        data: { turbo: false },
        style: "display: inline;"
      ) do
        render RubyUI::Button.new(type: :submit, variant: :outline) { "Gerar nova senha" }
      end
    end

    if allowed_to?(:destroy?, membership)
      form_with(
        url: membership_path(membership),
        method: :delete,
        local: true,
        style: "display: inline;"
      ) do
        render RubyUI::Button.new(
          type: :submit,
          variant: :destructive,
          data: { turbo_confirm: "Tem certeza?" }
        ) { "Remover" }
      end
    end
  end
end

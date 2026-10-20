# frozen_string_literal: true

class Views::Memberships::Index < Views::Base
  ROLE_BADGE_CLASSES = {
    "owner" => "bg-green-100 text-green-700",
    "admin" => "bg-blue-100 text-blue-700",
    "manager" => "bg-yellow-100 text-yellow-700",
    "viewer" => "bg-gray-100 text-gray-700"
  }.freeze

  ICON_CLASSES = "size-4"

  def initialize(memberships:)
    @memberships = memberships
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      render Components::PageHeader.new(title: "Funcionários", description: "Pessoas com acesso à organização e o cargo de cada uma.") do
        render RubyUI::Link.new(href: new_membership_path, variant: :primary) { "Novo funcionário" }
      end

      render_toolbar
      render_table
    end
  end

  private

  def render_toolbar
    div(class: "mb-4 flex justify-end") do
      p(class: "text-sm text-gray-600") { pluralize(@memberships.size, "funcionário", plural: "funcionários") }
    end
  end

  def render_table
    div(class: "rounded-lg border bg-white") do
      render RubyUI::Table.new do
        render RubyUI::TableHeader.new do
          render RubyUI::TableRow.new do
            render RubyUI::TableHead.new(class: "pl-4") { "Nome de usuário" }
            render RubyUI::TableHead.new(class: "hidden sm:table-cell") { "E-mail" }
            render RubyUI::TableHead.new { "Cargo" }
            render RubyUI::TableHead.new(class: "pr-4 text-right") { span(class: "sr-only") { "Ações" } }
          end
        end

        render RubyUI::TableBody.new do
          @memberships.each { |membership| render_membership_row(membership) }
        end
      end
    end
  end

  def render_membership_row(membership)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new(class: "pl-4") do
        p(class: "font-medium text-gray-900") do
          plain membership.user.username
          span(class: "ml-1 text-xs font-normal text-gray-500") { "(você)" } if membership == Current.membership
        end
        # Em telas pequenas, o e-mail sai da coluna e aparece sob o nome.
        p(class: "mt-0.5 break-all text-xs text-gray-500 sm:hidden") { membership.user.email_address }
      end
      render RubyUI::TableCell.new(class: "hidden break-all sm:table-cell") { membership.user.email_address }
      render RubyUI::TableCell.new { render_role_badge(membership) }
      render RubyUI::TableCell.new(class: "pr-4") do
        div(class: "flex items-center justify-end gap-0.5 sm:gap-1") { render_membership_actions(membership) }
      end
    end
  end

  def render_role_badge(membership)
    span(class: "inline-flex whitespace-nowrap rounded-full px-2 py-1 text-xs font-medium #{ROLE_BADGE_CLASSES.fetch(membership.role)}") do
      membership.role_label
    end
  end

  def render_membership_actions(membership)
    render_edit_link(membership) if allowed_to?(:edit?, membership)
    render_reset_password(membership) if allowed_to?(:reset_password?, membership)
    render_destroy(membership) if allowed_to?(:destroy?, membership)
  end

  def render_edit_link(membership)
    render RubyUI::Link.new(href: edit_membership_path(membership), variant: :ghost, icon: true, title: "Editar", class: "size-8 sm:size-9") do
      render PhlexIcons::Lucide::Pencil.new(class: ICON_CLASSES, aria: { hidden: true })
      span(class: "sr-only") { "Editar" }
    end
  end

  def render_reset_password(membership)
    # Sem Turbo: a resposta 200 com a nova senha precisa ser renderizada.
    # turbo_confirm não roda com Turbo desligado, por isso a confirmação é do controller "confirm".
    form_with(
      url: reset_password_membership_path(membership),
      method: :post,
      local: true,
      class: "inline-flex",
      data: {
        turbo: false,
        controller: "confirm",
        action: "submit->confirm#ask",
        confirm_message_value: "Gerar nova senha para este funcionário? A senha atual deixará de funcionar."
      }
    ) do
      render RubyUI::Button.new(type: :submit, variant: :ghost, icon: true, title: "Gerar nova senha", class: "size-8 sm:size-9") do
        render PhlexIcons::Lucide::KeyRound.new(class: ICON_CLASSES, aria: { hidden: true })
        span(class: "sr-only") { "Gerar nova senha" }
      end
    end
  end

  def render_destroy(membership)
    form_with(url: membership_path(membership), method: :delete, local: true, class: "inline-flex") do
      render RubyUI::Button.new(
        type: :submit,
        variant: :ghost,
        icon: true,
        title: "Remover",
        class: "size-8 text-destructive hover:bg-destructive/10 hover:text-destructive sm:size-9",
        data: { turbo_confirm: "Tem certeza que deseja remover este funcionário da organização?" }
      ) do
        render PhlexIcons::Lucide::UserMinus.new(class: ICON_CLASSES, aria: { hidden: true })
        span(class: "sr-only") { "Remover" }
      end
    end
  end
end

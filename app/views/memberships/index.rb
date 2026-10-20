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
      render RubyUI::TableCell.new(class: "text-right")
    end
  end
end

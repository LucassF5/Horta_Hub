# frozen_string_literal: true

class Views::Clients::Index < Views::Base
  def initialize(clients:)
    @clients = clients
  end

  def view_template
    div(class: "grow") do
      div(class: "container mx-auto px-4 py-8") do
        render_header
        render_content
      end
    end
  end

  private

  def render_header
    div(class: "flex justify-between items-center mb-6") do
      h1(class: "text-3xl font-bold text-gray-800") { "Clientes" }
      render RubyUI::Link.new(href: new_client_path, variant: :primary) { "Novo Cliente" }
    end
  end

  def render_content
    if @clients.empty?
      p(class: "text-gray-600") { "Nenhum cliente cadastrado ainda." }
    else
      render_table
    end
  end

  def render_table
    render RubyUI::Table.new do
      render RubyUI::TableHeader.new do
        render RubyUI::TableRow.new do
          render RubyUI::TableHead.new { "Nome" }
          render RubyUI::TableHead.new { "Telefone" }
          render RubyUI::TableHead.new { "Tipo" }
          render RubyUI::TableHead.new(class: "text-right") { "Ações" }
        end
      end

      render RubyUI::TableBody.new do
        @clients.each { |client| render_client_row(client) }
      end
    end
  end

  def render_client_row(client)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new { client.name }
      render RubyUI::TableCell.new { client.phone }
      render RubyUI::TableCell.new { client.client_type.humanize }
      render RubyUI::TableCell.new(class: "text-right") do
        div(class: "flex justify-end items-center gap-2") do
          render RubyUI::Link.new(href: client_path(client), variant: :outline) { "Ver" }
          render RubyUI::Link.new(href: edit_client_path(client), variant: :primary) { "Editar" }

          form_with(
            url: client_path(client),
            method: :delete,
            local: true,
            style: "display: inline;"
          ) do
            render RubyUI::Button.new(
              type: :submit,
              variant: :destructive,
              data: { turbo_confirm: "Tem certeza?" }
            ) { "Apagar" }
          end
        end
      end
    end
  end
end

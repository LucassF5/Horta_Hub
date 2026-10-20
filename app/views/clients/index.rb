# frozen_string_literal: true

class Views::Clients::Index < Views::Base
  def initialize(clients:, listing:)
    @clients = clients
    @listing = listing
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      render Components::PageHeader.new(title: "Clientes", description: "Pessoas e empresas que compram da organização.") do
        # No primeiro uso o estado vazio já oferece o cadastro.
        render RubyUI::Link.new(href: new_client_path, variant: :primary) { "Novo Cliente" } if allowed_to?(:create?, Client) && !first_use?
      end

      render_content
    end
  end

  private

  def first_use?
    @clients.empty? && !@listing.search?
  end

  def render_content
    if first_use?
      render_empty_state
    else
      render_toolbar
      @clients.empty? ? render_no_results : render_table
    end
  end

  def render_toolbar
    div(class: "mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between") do
      render Components::Listings::SearchForm.new(
        url: clients_path,
        listing: @listing,
        label: "Buscar clientes",
        placeholder: "Nome ou telefone"
      )
      p(class: "text-sm text-gray-600") { pluralize(@clients.size, "cliente", plural: "clientes") } if @clients.any?
    end
  end

  def render_table
    div(class: "rounded-lg border bg-white") do
      render RubyUI::Table.new do
        render RubyUI::TableHeader.new do
          render RubyUI::TableRow.new do
            sortable_head("Nome", "name", class: "pl-4")
            render RubyUI::TableHead.new(class: "hidden sm:table-cell") { "Telefone" }
            sortable_head("Tipo", "client_type", class: "hidden md:table-cell")
            render RubyUI::TableHead.new(class: "pr-4 text-right") { span(class: "sr-only") { "Ações" } }
          end
        end

        render RubyUI::TableBody.new do
          @clients.each { |client| render_client_row(client) }
        end
      end
    end
  end

  def sortable_head(label, column, **attrs)
    render Components::Listings::SortableHead.new(
      label: label,
      column: column,
      listing: @listing,
      href: clients_path(@listing.sort_params(column)),
      **attrs
    )
  end

  def render_client_row(client)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new(class: "pl-4") do
        a(href: client_path(client), class: "font-medium text-gray-900 hover:underline") { client.name }
        # Em telas pequenas, telefone e tipo saem das colunas e aparecem sob o nome.
        p(class: "mt-0.5 flex flex-wrap gap-x-3 text-xs text-gray-500 md:hidden") do
          span(class: "tabular-nums sm:hidden") { client.phone } if client.phone.present?
          span { client_type_label(client) }
        end
      end
      render RubyUI::TableCell.new(class: "hidden tabular-nums sm:table-cell") { client.phone.presence || "-" }
      render RubyUI::TableCell.new(class: "hidden md:table-cell") { client_type_label(client) }
      render RubyUI::TableCell.new(class: "pr-4") do
        render Components::Listings::RowActions.new(
          record: client,
          show_path: client_path(client),
          edit_path: edit_client_path(client),
          destroy_path: client_path(client),
          confirm: "Tem certeza que deseja apagar este cliente?"
        )
      end
    end
  end

  def client_type_label(client)
    Client.client_types[client.client_type]
  end

  def render_no_results
    render Components::Listings::EmptyState.new(
      icon: PhlexIcons::Lucide::SearchX,
      title: "Nenhum cliente encontrado",
      description: "Nenhum cliente tem \"#{@listing.query}\" no nome ou no telefone. Confira a grafia ou busque por outro termo."
    ) do
      render RubyUI::Link.new(href: clients_path, variant: :outline) { "Limpar busca" }
    end
  end

  def render_empty_state
    if allowed_to?(:create?, Client)
      render Components::Listings::EmptyState.new(
        icon: PhlexIcons::Lucide::Users,
        title: "Cadastre o primeiro cliente",
        description: "Toda venda é registrada para um cliente. Cadastre quem compra da sua horta para começar a vender."
      ) do
        render RubyUI::Link.new(href: new_client_path, variant: :primary) { "Novo Cliente" }
      end
    else
      render Components::Listings::EmptyState.new(
        icon: PhlexIcons::Lucide::Users,
        title: "Nenhum cliente cadastrado",
        description: "Os clientes cadastrados pela equipe da organização aparecem aqui."
      )
    end
  end
end

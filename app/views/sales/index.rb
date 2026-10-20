# frozen_string_literal: true

class Views::Sales::Index < Views::Base
  FILTER_KEYS = %i[start_date end_date status client_id].freeze

  def initialize(sales:, clients:, filters:, listing:)
    @sales = sales
    @clients = clients
    @filters = filters.to_h.symbolize_keys
    @listing = listing
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      render Components::PageHeader.new(title: "Vendas", description: "Vendas registradas, com status, cliente e total calculado pelos itens.") do
        # No primeiro uso o estado vazio já oferece o cadastro.
        render RubyUI::Link.new(href: new_sale_path, variant: :primary) { "Nova Venda" } if allowed_to?(:create?, Sale) && !first_use?
      end

      render_content
    end
  end

  private

  def filtering?
    @listing.search? || @filters.slice(*FILTER_KEYS).values.any?(&:present?)
  end

  def first_use?
    @sales.empty? && !filtering?
  end

  def render_content
    render_filters unless first_use?

    # O frame é sempre renderizado: um envio de filtro precisa encontrá-lo na resposta.
    turbo_frame_tag "sales_results", data: { turbo_action: "advance" } do
      if first_use?
        render_empty_state
      elsif @sales.empty?
        render_no_results
      else
        p(class: "mb-3 text-sm text-gray-600") { pluralize(@sales.size, "venda", plural: "vendas") }
        render_table
      end
    end
  end

  def render_filters
    form_with(
      url: sales_path,
      method: :get,
      local: true,
      class: "mb-6 grid grid-cols-2 gap-3 rounded-lg border bg-white p-4 sm:gap-4 lg:grid-cols-6",
      data: { turbo_frame: "sales_results" }
    ) do
      input(type: "hidden", name: "sort", value: @listing.sort)
      input(type: "hidden", name: "direction", value: @listing.direction)

      render RubyUI::FormField.new(class: "col-span-2") do
        render RubyUI::FormFieldLabel.new(for: "q") { "Buscar" }
        div(class: "relative") do
          render PhlexIcons::Lucide::Search.new(class: "pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground", aria: { hidden: true })
          input(type: "search", id: "q", name: "q", value: @listing.query, placeholder: "Cliente ou responsável", autocomplete: "off", class: "#{input_classes} pl-9")
        end
      end

      render RubyUI::FormField.new(class: "min-w-0") do
        render RubyUI::FormFieldLabel.new(for: "start_date") { "De" }
        input(type: "date", id: "start_date", name: "start_date", value: @filters[:start_date], class: input_classes)
      end

      render RubyUI::FormField.new(class: "min-w-0") do
        render RubyUI::FormFieldLabel.new(for: "end_date") { "Até" }
        input(type: "date", id: "end_date", name: "end_date", value: @filters[:end_date], class: input_classes)
      end

      render RubyUI::FormField.new(class: "min-w-0") do
        render RubyUI::FormFieldLabel.new(for: "status") { "Status" }
        select(id: "status", name: "status", class: input_classes) do
          option(value: "") { "Todos" }
          status_options.each do |label, value|
            option(value: value, selected: @filters[:status] == value) { label }
          end
        end
      end

      render RubyUI::FormField.new(class: "min-w-0") do
        render RubyUI::FormFieldLabel.new(for: "client_id") { "Cliente" }
        select(id: "client_id", name: "client_id", class: input_classes) do
          option(value: "") { "Todos" }
          @clients.each do |client|
            option(value: client.id, selected: @filters[:client_id].to_s == client.id.to_s) { client.name }
          end
        end
      end

      div(class: "col-span-2 flex items-end justify-end gap-2 lg:col-span-6") do
        render RubyUI::Link.new(href: sales_path, variant: :outline, data: { turbo_frame: "_top" }) { "Limpar" }
        render RubyUI::Button.new(type: :submit, class: "h-9") { "Filtrar" }
      end
    end
  end

  def render_table
    div(class: "rounded-lg border bg-white") do
      render RubyUI::Table.new do
        render RubyUI::TableHeader.new do
          render RubyUI::TableRow.new do
            sortable_head("Data", "sale_date", class: "hidden pl-4 sm:table-cell")
            sortable_head("Cliente", "client", class: "pl-4 sm:pl-2")
            render RubyUI::TableHead.new(class: "hidden lg:table-cell") { "Responsável" }
            sortable_head("Status", "status", class: "hidden sm:table-cell")
            sortable_head("Total", "total", class: "text-right")
            render RubyUI::TableHead.new(class: "pr-4 text-right") { span(class: "sr-only") { "Ações" } }
          end
        end

        render RubyUI::TableBody.new do
          @sales.each { |sale| render_sale_row(sale) }
        end
      end
    end
  end

  def sortable_head(label, column, **attrs)
    render Components::Listings::SortableHead.new(
      label: label,
      column: column,
      listing: @listing,
      href: sales_path(@filters.slice(*FILTER_KEYS).compact_blank.merge(@listing.sort_params(column))),
      **attrs
    )
  end

  def render_sale_row(sale)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new(class: "hidden whitespace-nowrap pl-4 tabular-nums sm:table-cell") { l(sale.sale_date, format: :short) }
      render RubyUI::TableCell.new(class: "pl-4 sm:pl-2") do
        a(href: sale_path(sale), class: "font-medium text-gray-900 hover:underline", data: { turbo_frame: "_top" }) { sale.client.name }
        # Em telas pequenas data e status saem das colunas e aparecem sob o cliente.
        div(class: "mt-1 flex items-center gap-2 text-xs text-gray-500 sm:hidden") do
          span(class: "tabular-nums") { l(sale.sale_date, format: :short) }
          render Components::Sales::StatusBadge.new(status: sale.status)
        end
      end
      render RubyUI::TableCell.new(class: "hidden lg:table-cell") { sale.responsible_name.presence || "-" }
      render RubyUI::TableCell.new(class: "hidden sm:table-cell") { render Components::Sales::StatusBadge.new(status: sale.status) }
      render RubyUI::TableCell.new(class: "whitespace-nowrap text-right tabular-nums") { number_to_currency(sale.total) }
      render RubyUI::TableCell.new(class: "pr-4") do
        render Components::Listings::RowActions.new(
          record: sale,
          show_path: sale_path(sale),
          edit_path: edit_sale_path(sale),
          destroy_path: sale_path(sale),
          confirm: "Tem certeza que deseja apagar esta venda?"
        )
      end
    end
  end

  def render_no_results
    render Components::Listings::EmptyState.new(
      icon: PhlexIcons::Lucide::SearchX,
      title: "Nenhuma venda encontrada",
      description: "Nenhuma venda atende à busca e aos filtros escolhidos. Amplie o período ou remova algum filtro."
    ) do
      render RubyUI::Link.new(href: sales_path, variant: :outline, data: { turbo_frame: "_top" }) { "Limpar filtros" }
    end
  end

  def render_empty_state
    if allowed_to?(:create?, Sale)
      render Components::Listings::EmptyState.new(
        icon: PhlexIcons::Lucide::ShoppingCart,
        title: "Registre a primeira venda",
        description: "Escolha o cliente, adicione os produtos vendidos e o total é calculado automaticamente. Para trazer o histórico de uma planilha, use a importação."
      ) do
        render RubyUI::Link.new(href: new_sale_path, variant: :primary) { "Nova Venda" }
        render RubyUI::Link.new(href: new_import_batch_path, variant: :outline) { "Importar planilha" } if allowed_to?(:create?, ImportBatch)
      end
    else
      render Components::Listings::EmptyState.new(
        icon: PhlexIcons::Lucide::ShoppingCart,
        title: "Nenhuma venda registrada",
        description: "As vendas registradas pela equipe da organização aparecem aqui."
      )
    end
  end

  def status_options
    [
      [ "Pendente", "pending" ],
      [ "Concluída", "completed" ],
      [ "Cancelada", "cancelled" ]
    ]
  end

  def input_classes
    [
      "flex h-9 w-full min-w-0 rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "placeholder:text-muted-foreground",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end

# frozen_string_literal: true

class Views::Sales::Index < Views::Base
  def initialize(sales:, clients:, filters:)
    @sales = sales
    @clients = clients
    @filters = filters.to_h.symbolize_keys
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
      h1(class: "text-3xl font-bold text-gray-800") { "Vendas" }
      render RubyUI::Link.new(href: new_sale_path, variant: :primary) { "Nova Venda" } if allowed_to?(:create?, Sale)
    end
  end

  def render_content
    render_filters

    turbo_frame_tag "sales_results" do
      if @sales.empty?
        p(class: "text-gray-600") { "Nenhuma venda encontrada." }
      else
        render_table
      end
    end
  end

  def render_filters
    form_with(
      url: sales_path,
      method: :get,
      local: true,
      class: "mb-6 grid grid-cols-1 gap-4 rounded-md border bg-white p-4 md:grid-cols-5",
      data: { turbo_frame: "sales_results" }
    ) do
      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "start_date") { "De" }
        input(type: "date", id: "start_date", name: "start_date", value: @filters[:start_date], class: input_classes)
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "end_date") { "Até" }
        input(type: "date", id: "end_date", name: "end_date", value: @filters[:end_date], class: input_classes)
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "status") { "Status" }
        select(id: "status", name: "status", class: input_classes) do
          option(value: "") { "Todos" }
          status_options.each do |label, value|
            option(value: value, selected: @filters[:status] == value) { label }
          end
        end
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "client_id") { "Cliente" }
        select(id: "client_id", name: "client_id", class: input_classes) do
          option(value: "") { "Todos" }
          @clients.each do |client|
            option(value: client.id, selected: @filters[:client_id].to_s == client.id.to_s) { client.name }
          end
        end
      end

      div(class: "flex items-end gap-2") do
        render RubyUI::Button.new(type: :submit, class: "h-9") { "Filtrar" }
        render RubyUI::Link.new(href: sales_path, variant: :outline, data: { turbo_frame: "sales_results" }) { "Limpar" }
      end
    end
  end

  def render_table
    render RubyUI::Table.new do
      render RubyUI::TableHeader.new do
        render RubyUI::TableRow.new do
          render RubyUI::TableHead.new { "Data" }
          render RubyUI::TableHead.new { "Cliente" }
          render RubyUI::TableHead.new { "Status" }
          render RubyUI::TableHead.new { "Total" }
          render RubyUI::TableHead.new(class: "text-right") { "Ações" }
        end
      end

      render RubyUI::TableBody.new do
        @sales.each { |sale| render_sale_row(sale) }
      end
    end
  end

  def render_sale_row(sale)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new { l(sale.sale_date, format: :short) }
      render RubyUI::TableCell.new { sale.client.name }
      render RubyUI::TableCell.new { render_status_badge(sale) }
      render RubyUI::TableCell.new { number_to_currency(sale.total, unit: "R$ ") }
      render RubyUI::TableCell.new(class: "text-right") do
        div(class: "flex justify-end items-center gap-2") do
          render RubyUI::Link.new(href: sale_path(sale), variant: :outline, data: { turbo_frame: "_top" }) { "Ver" }
          render RubyUI::Link.new(href: edit_sale_path(sale), variant: :primary, data: { turbo_frame: "_top" }) { "Editar" } if allowed_to?(:edit?, sale)

          if allowed_to?(:destroy?, sale)
            form_with(
              url: sale_path(sale),
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

  def render_status_badge(sale)
    color = case sale.status
    when "completed" then "text-green-700 bg-green-100"
    when "pending" then "text-yellow-700 bg-yellow-100"
    when "cancelled" then "text-red-700 bg-red-100"
    end

    label = case sale.status
    when "completed" then "Concluída"
    when "pending" then "Pendente"
    when "cancelled" then "Cancelada"
    end

    span(class: "px-2 py-1 rounded-full text-xs font-medium #{color}") { label }
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
      "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "placeholder:text-muted-foreground",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end

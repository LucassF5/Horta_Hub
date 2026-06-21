# frozen_string_literal: true

class Views::Home::Index < Views::Base
  def initialize(dashboard:)
    @dashboard = dashboard
  end

  def view_template
    div(class: "container mx-auto py-4 md:py-8") do
      render_header
      render_metrics

      div(class: "mt-6 grid gap-6 xl:grid-cols-2") do
        render_recent_sales
        render_top_products
      end

      div(class: "mt-6") { render_cancelled_sales }
    end
  end

  private

  attr_reader :dashboard

  def render_header
    div(class: "mb-6 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between") do
      div do
        h1(class: "text-3xl font-bold tracking-tight text-gray-900") { "Dashboard" }
        p(class: "mt-1 text-sm text-gray-600") { "Visão operacional de #{I18n.l(Date.current, format: "%B de %Y")}." }
      end

      render_shortcuts
    end
  end

  def render_shortcuts
    actions = [
      [ allowed_to?(:create?, Sale), new_sale_path, "Nova venda", :primary ],
      [ allowed_to?(:create?, Client), new_client_path, "Novo cliente", :outline ],
      [ allowed_to?(:create?, Product), new_product_path, "Novo produto", :outline ]
    ].select(&:first)

    return if actions.empty?

    div(class: "flex flex-wrap gap-2", aria: { label: "Atalhos" }) do
      actions.each do |_allowed, path, label, variant|
        render RubyUI::Link.new(href: path, variant: variant) { label }
      end
    end
  end

  def render_metrics
    div(class: "grid gap-4 sm:grid-cols-2 xl:grid-cols-3") do
      render_metric_card(
        id: "revenue",
        title: "Receita do mês",
        value: currency(dashboard.revenue),
        detail: comparison_text(dashboard.revenue_change)
      )
      render_metric_card(
        id: "sales",
        title: "Vendas do mês",
        value: dashboard.sales_count.to_s,
        detail: comparison_text(dashboard.sales_count_change)
      )
      render_metric_card(
        id: "pending",
        title: "Pendentes",
        value: dashboard.pending_count.to_s,
        detail: "#{currency(dashboard.pending_value)} em aberto"
      )
      render_metric_card(
        id: "cancelled",
        title: "Canceladas",
        value: dashboard.cancelled_count.to_s,
        detail: "#{currency(dashboard.cancelled_value)} cancelados"
      )
      render_metric_card(
        id: "clients",
        title: "Clientes",
        value: dashboard.clients_count.to_s,
        detail: "cadastrados na organização"
      )
      render_metric_card(
        id: "products",
        title: "Produtos",
        value: dashboard.products_count.to_s,
        detail: "cadastrados na organização"
      )
    end
  end

  def render_metric_card(id:, title:, value:, detail:)
    render RubyUI::Card.new(id: "metric-#{id}", class: "h-full") do
      render RubyUI::CardHeader.new(class: "pb-2") do
        render RubyUI::CardDescription.new { title }
        render RubyUI::CardTitle.new(class: "text-3xl") { value }
      end
      render RubyUI::CardContent.new do
        p(class: "text-xs text-muted-foreground") { detail }
      end
    end
  end

  def render_recent_sales
    render_list_card(
      title: "Vendas recentes",
      description: "As últimas vendas registradas, independentemente do status."
    ) do
      if dashboard.recent_sales.empty?
        render_empty_state("Nenhuma venda cadastrada ainda.")
      else
        ul(class: "divide-y divide-gray-100") do
          dashboard.recent_sales.each { |sale| render_sale_item(sale) }
        end
      end
    end
  end

  def render_cancelled_sales
    render_list_card(
      title: "Cancelamentos do mês",
      description: "Vendas canceladas para acompanhamento operacional."
    ) do
      if dashboard.cancelled_sales.empty?
        render_empty_state("Nenhuma venda cancelada neste mês.")
      else
        ul(class: "grid divide-y divide-gray-100 lg:grid-cols-2 lg:gap-x-8 lg:divide-y-0") do
          dashboard.cancelled_sales.each { |sale| render_sale_item(sale) }
        end
      end
    end
  end

  def render_sale_item(sale)
    li do
      a(
        href: sale_path(sale),
        class: "flex items-center justify-between gap-4 rounded-md px-1 py-3 transition-colors hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-primary"
      ) do
        div(class: "min-w-0") do
          p(class: "truncate font-medium text-gray-900") { sale.client.name }
          p(class: "mt-1 text-xs text-gray-500") { I18n.l(sale.sale_date, format: :short) }
        end
        div(class: "flex shrink-0 items-center gap-3") do
          render_status_badge(sale.status)
          span(class: "font-medium tabular-nums text-gray-900") { currency(sale.total) }
        end
      end
    end
  end

  def render_top_products
    render_list_card(
      title: "Produtos mais vendidos",
      description: "Unidades em vendas concluídas neste mês."
    ) do
      if dashboard.top_products.empty?
        render_empty_state("Ainda não há produtos em vendas concluídas neste mês.")
      else
        ol(class: "divide-y divide-gray-100") do
          dashboard.top_products.each_with_index do |product, index|
            li do
              a(
                href: product_path(product),
                class: "flex items-center gap-3 rounded-md px-1 py-3 transition-colors hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-primary"
              ) do
                span(class: "flex size-8 shrink-0 items-center justify-center rounded-full bg-green-50 text-sm font-semibold text-green-700") do
                  (index + 1).to_s
                end
                div(class: "min-w-0 flex-1") do
                  p(class: "truncate font-medium text-gray-900") { product.name }
                end
                span(class: "shrink-0 text-sm text-gray-600") do
                  "#{product.units_sold.to_i} #{product.units_sold.to_i == 1 ? "unidade" : "unidades"}"
                end
              end
            end
          end
        end
      end
    end
  end

  def render_list_card(title:, description:, &block)
    render RubyUI::Card.new(class: "h-full") do
      render RubyUI::CardHeader.new do
        render RubyUI::CardTitle.new { title }
        render RubyUI::CardDescription.new { description }
      end
      render RubyUI::CardContent.new(&block)
    end
  end

  def render_empty_state(message)
    div(class: "rounded-lg border border-dashed border-gray-200 px-4 py-8 text-center text-sm text-gray-500") { message }
  end

  def render_status_badge(status)
    label, classes = case status
    when "completed" then [ "Concluída", "bg-green-100 text-green-700" ]
    when "pending" then [ "Pendente", "bg-yellow-100 text-yellow-700" ]
    when "cancelled" then [ "Cancelada", "bg-red-100 text-red-700" ]
    end

    span(class: "rounded-full px-2 py-1 text-xs font-medium #{classes}") { label }
  end

  def comparison_text(change)
    return "Sem base no mês anterior" if change.nil?

    prefix = "+" if change.positive?
    "#{prefix}#{Kernel.format("%.1f", change).tr(".", ",")}% vs. mês anterior"
  end

  def currency(value)
    number_to_currency(value, unit: "R$", separator: ",", delimiter: ".")
  end
end

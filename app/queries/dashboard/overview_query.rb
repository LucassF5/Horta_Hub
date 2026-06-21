# frozen_string_literal: true

class Dashboard::OverviewQuery
  LIST_LIMIT = 5

  attr_reader :revenue,
    :sales_count,
    :pending_count,
    :pending_value,
    :cancelled_count,
    :cancelled_value,
    :clients_count,
    :products_count,
    :revenue_change,
    :sales_count_change,
    :recent_sales,
    :cancelled_sales,
    :top_products

  def initialize(organization:, today: Date.current)
    @organization = organization
    @today = today

    load_metrics
    load_lists
  end

  private

  attr_reader :organization, :today

  def load_metrics
    current_sales = sales_in(current_month)
    previous_sales = sales_in(previous_month)

    @revenue = current_sales.completed.sum(:total)
    @sales_count = current_sales.count
    @pending_count = current_sales.pending.count
    @pending_value = current_sales.pending.sum(:total)
    @cancelled_count = current_sales.cancelled.count
    @cancelled_value = current_sales.cancelled.sum(:total)
    @clients_count = organization.clients.count
    @products_count = organization.products.count
    @revenue_change = percentage_change(@revenue, previous_sales.completed.sum(:total))
    @sales_count_change = percentage_change(@sales_count, previous_sales.count)
  end

  def load_lists
    @recent_sales = organization.sales
      .includes(:client)
      .order(sale_date: :desc, created_at: :desc, id: :desc)
      .limit(LIST_LIMIT)

    @cancelled_sales = sales_in(current_month)
      .cancelled
      .includes(:client)
      .order(sale_date: :desc, created_at: :desc, id: :desc)
      .limit(LIST_LIMIT)

    @top_products = organization.products
      .joins(sale_items: :sale)
      .where(sales: { organization_id: organization.id, status: "completed", sale_date: current_month })
      .select("products.*, SUM(sale_items.quantity) AS units_sold")
      .group("products.id")
      .order(Arel.sql("SUM(sale_items.quantity) DESC, products.name ASC"))
      .limit(LIST_LIMIT)
  end

  def sales_in(period)
    organization.sales.where(sale_date: period)
  end

  def current_month
    today.beginning_of_month..today.end_of_month
  end

  def previous_month
    previous_month_date = today.prev_month
    previous_month_date.beginning_of_month..previous_month_date.end_of_month
  end

  def percentage_change(current_value, previous_value)
    return if previous_value.zero?

    (((current_value.to_d - previous_value.to_d) / previous_value.to_d) * 100).round(1)
  end
end

# frozen_string_literal: true

class Reports::ProductBreakdown
  Row = Data.define(:product, :quantity, :revenue, :share, :change, :first_sold_in_month)
  Line = Data.define(:product, :quantity, :revenue, :selected_quantity, :base_quantity, :first_sold_on)
  private_constant :Line

  def initialize(scope:, period:)
    @scope = scope
    @period = period
  end

  def rows
    @rows ||= begin
      lines = build_lines
      total = lines.sum(&:revenue)

      lines
        .sort_by { |line| [ -line.quantity, line.product.name ] }
        .map { |line| row(line, total) }
    end
  end

  private

  attr_reader :scope, :period

  def build_lines
    selected_window, base_window = period.base_windows
    selected = quantities(selected_window)
    base = quantities(base_window)
    products = Product.where(id: first_sales.keys).index_by(&:id)

    first_sales.map do |product_id, first_sold_on|
      quantity, revenue = month_totals.fetch(product_id, [ 0, 0.to_d ])

      Line.new(
        product: products.fetch(product_id),
        quantity: quantity,
        revenue: revenue,
        selected_quantity: selected.fetch(product_id, 0),
        base_quantity: base.fetch(product_id, 0),
        first_sold_on: first_sold_on
      )
    end
  end

  def row(line, total)
    Row.new(
      product: line.product,
      quantity: line.quantity,
      revenue: line.revenue,
      share: Percentage.share(line.revenue, total),
      change: Percentage.change(line.selected_quantity, line.base_quantity),
      first_sold_in_month: first_sold_in_month?(line)
    )
  end

  def first_sold_in_month?(line)
    period.range.cover?(line.first_sold_on) && line.selected_quantity.positive? && line.base_quantity.zero?
  end

  # Primeira venda concluída de cada produto na organização. Ignora o filtro de vendedor
  # para que a data de estreia não dependa de quem vendeu.
  def first_sales
    @first_sales ||= completed_items
      .group(:product_id)
      .pluck(:product_id, Arel.sql("MIN(sales.sale_date)"))
      .to_h { |product_id, sold_on| [ product_id, sold_on.to_date ] }
  end

  def month_totals
    @month_totals ||= scope.items(period.range)
      .group(:product_id)
      .pluck(
        :product_id,
        Arel.sql("SUM(sale_items.quantity)"),
        Arel.sql("SUM(sale_items.quantity * sale_items.unit_price)")
      )
      .to_h { |product_id, quantity, revenue| [ product_id, [ quantity.to_i, revenue.to_d.round(2) ] ] }
  end

  def quantities(range)
    scope.items(range).group(:product_id).sum(:quantity)
  end

  def completed_items
    relation = SaleItem.joins(:sale).where(sales: { organization_id: scope.organization.id, status: "completed" })
    scope.product ? relation.where(product_id: scope.product.id) : relation
  end
end

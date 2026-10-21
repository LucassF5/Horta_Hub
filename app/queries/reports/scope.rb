# frozen_string_literal: true

class Reports::Scope
  Totals = Data.define(:revenue, :sales_count, :units) do
    def self.zero = new(revenue: 0, sales_count: 0, units: 0)

    def ticket
      return if sales_count.zero?

      (revenue.to_d / sales_count).round(2)
    end
  end

  attr_reader :organization, :product, :seller_key

  def initialize(organization:, product: nil, seller_key: nil)
    @organization = organization
    @product = product
    @seller_key = seller_key
    @totals = {}
  end

  def items(range, status: "completed")
    filtered_items(range, status: status)
  end

  def totals(range)
    @totals[range] ||= load_totals(range)
  end

  private

  def filtered_items(range, status:)
    relation = SaleItem.joins(:sale).where(sales: { organization_id: organization.id, status: status, sale_date: range })
    relation = relation.where(product_id: product.id) if product
    relation = relation.merge(Reports::SellerKey.sales_condition(seller_key, organization: organization)) if seller_key
    relation
  end

  def load_totals(range)
    rows = filtered_items(range, status: Sale.statuses.values)
      .group("sales.status")
      .pluck(
        Arel.sql("sales.status"),
        Arel.sql("SUM(sale_items.quantity * sale_items.unit_price)"),
        Arel.sql("COUNT(DISTINCT sale_items.sale_id)"),
        Arel.sql("SUM(sale_items.quantity)")
      )

    totals = Sale.statuses.values.index_with { Totals.zero }
    rows.each do |status, revenue, sales_count, units|
      totals[status] = Totals.new(revenue: revenue.to_d.round(2), sales_count: sales_count.to_i, units: units.to_i)
    end
    totals
  end
end

# frozen_string_literal: true

class Reports::SellerBreakdown
  Row = Data.define(:key, :name, :kind, :sales_count, :revenue, :share, :change)

  def initialize(scope:, period:)
    @scope = scope
    @period = period
  end

  def rows
    @rows ||= begin
      month = totals_by_key(period.range)
      total = month.values.sum { |_sales_count, revenue| revenue }
      selected, base = period.base_windows.map { |window| revenue_by_key(window) }
      names = names_for(month.keys)

      sellers = month.map do |key, (sales_count, revenue)|
        Row.new(
          key: key,
          name: names.fetch(key),
          kind: kind_for(key),
          sales_count: sales_count,
          revenue: revenue,
          share: Percentage.share(revenue, total),
          change: Percentage.change(selected.fetch(key, 0), base.fetch(key, 0))
        )
      end

      sellers.sort_by { |row| [ -row.revenue, row.name ] }
    end
  end

  private

  attr_reader :scope, :period

  # Grupos (vínculo, nome em texto) com a mesma chave se somam. Cada venda cai em um só grupo.
  def totals_by_key(range)
    scope.items(range)
      .group("sales.seller_id", "sales.responsible_name")
      .pluck(
        "sales.seller_id",
        "sales.responsible_name",
        Arel.sql("COUNT(DISTINCT sale_items.sale_id)"),
        Arel.sql("SUM(sale_items.quantity * sale_items.unit_price)")
      )
      .each_with_object({}) do |(seller_id, responsible_name, sales_count, revenue), totals|
        key = Reports::SellerKey.for(seller_id: seller_id, responsible_name: responsible_name)
        count, sum = totals.fetch(key, [ 0, 0.to_d ])
        totals[key] = [ count + sales_count.to_i, sum + revenue.to_d.round(2) ]
      end
  end

  def revenue_by_key(range)
    totals_by_key(range).transform_values(&:last)
  end

  # Usuários são buscados por id, sem filtrar pela organização: quem saiu continua aparecendo.
  def names_for(keys)
    usernames = User.where(id: keys.filter_map { |key| user_id(key) }).pluck(:id, :username).to_h
    labels = Reports::SellerKey.name_labels(scope.organization)

    keys.index_with do |key|
      case kind_for(key)
      when :user then usernames.fetch(user_id(key))
      when :name then labels.fetch(key)
      else Sale::UNLINKED_SELLER_NAME
      end
    end
  end

  def kind_for(key)
    case key
    when Reports::SellerKey::USER_KEY then :user
    when Reports::SellerKey::NAME_KEY then :name
    else :none
    end
  end

  def user_id(key)
    key[Reports::SellerKey::USER_KEY, 1]&.to_i
  end
end

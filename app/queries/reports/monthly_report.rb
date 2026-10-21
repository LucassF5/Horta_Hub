# frozen_string_literal: true

class Reports::MonthlyReport
  attr_reader :period, :product, :seller_key

  def initialize(organization:, filters:)
    @organization = organization
    @period = filters.period
    @product = filters.product
    @seller_key = known_seller_key(filters.seller_key)
  end

  def summary
    @summary ||= Reports::Summary.new(scope: scope, period: period)
  end

  def year_points
    @year_points ||= Reports::YearSeries.new(scope: scope, period: period).points
  end

  def product_rows
    @product_rows ||= Reports::ProductBreakdown.new(scope: scope, period: period).rows
  end

  def seller_rows
    @seller_rows ||= Reports::SellerBreakdown.new(scope: scope, period: period).rows
  end

  def month_options
    earliest = [ first_sale_month, period.month ].compact.min
    Enumerator.produce(period.current_month, &:prev_month).take_while { |month| month >= earliest }
  end

  def product_options
    organization.products.order(:name)
  end

  def seller_options
    @seller_options ||= Reports::SellerKey.options(organization)
  end

  private

  attr_reader :organization

  # Só aplica a chave que está no seletor: senão a filtragem ocorre sem que o select a mostre.
  def known_seller_key(key)
    return if key.nil?

    key if seller_options.any? { |_label, option_key| option_key == key }
  end

  def scope
    @scope ||= Reports::Scope.new(organization: organization, product: product, seller_key: seller_key)
  end

  # Qualquer status: o mês da primeira venda define até onde o seletor volta.
  def first_sale_month
    organization.sales.minimum(:sale_date)&.to_date&.beginning_of_month
  end
end

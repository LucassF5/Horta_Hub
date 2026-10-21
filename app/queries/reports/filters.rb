# frozen_string_literal: true

class Reports::Filters
  def initialize(params, organization:, today: Date.current)
    @params = params
    @organization = organization
    @today = today
  end

  def period
    @period ||= Reports::Period.new(month: month, comparison: params[:comparison], today: today)
  end

  def product
    return if params[:product_id].blank?

    organization.products.find_by(id: params[:product_id])
  end

  def seller_key
    key = params[:seller]
    key if Reports::SellerKey.valid?(key)
  end

  private

  attr_reader :params, :organization, :today

  def month
    value = params[:month]
    return today.beginning_of_month if value.blank?

    parsed = Date.strptime(value, "%Y-%m")
    parsed.year < 2000 ? today.beginning_of_month : parsed
  rescue Date::Error, TypeError, ArgumentError
    today.beginning_of_month
  end
end

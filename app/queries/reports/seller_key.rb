# frozen_string_literal: true

module Reports::SellerKey
  UNLINKED = "none"
  USER_KEY = /\Auser:(\d+)\z/
  NAME_KEY = /\Aname:(.+)\z/

  module_function

  def for(seller_id:, responsible_name:)
    return "user:#{seller_id}" if seller_id

    normalized = PersonName.normalize(responsible_name)
    return UNLINKED if normalized.empty?

    "name:#{normalized}"
  end

  def valid?(key)
    key.is_a?(String) && (key == UNLINKED || USER_KEY.match?(key) || NAME_KEY.match?(key))
  end

  def sales_condition(key, organization:)
    base = organization.sales

    case key
    when USER_KEY
      base.where(seller_id: Regexp.last_match(1))
    when NAME_KEY
      base.where(seller_id: nil, responsible_name: name_variants(Regexp.last_match(1), organization: organization))
    when UNLINKED
      base.where(seller_id: nil).where("TRIM(COALESCE(sales.responsible_name, '')) = ''")
    else
      raise ArgumentError, "chave de vendedor inválida: #{key.inspect}"
    end
  end

  def name_variants(normalized_name, organization:)
    organization.sales
      .where(seller_id: nil)
      .where.not(responsible_name: nil)
      .distinct
      .pluck(:responsible_name)
      .select { |variant| PersonName.normalize(variant) == normalized_name }
  end
  private_class_method :name_variants
end

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

  # Rótulo de exibição por chave "name:N": a grafia alfabeticamente menor entre as vendas sem vínculo.
  def name_labels(organization)
    variants = organization.sales
      .where(seller_id: nil)
      .where.not(responsible_name: nil)
      .distinct
      .pluck(:responsible_name)

    variants
      .group_by { |variant| self.for(seller_id: nil, responsible_name: variant) }
      .except(UNLINKED)
      .transform_values(&:min)
  end

  def options(organization)
    users = User.where(id: organization.memberships.select(:user_id))
      .or(User.where(id: organization.sales.where.not(seller_id: nil).select(:seller_id)))
      .order(:username)

    user_options = users.map { |user| [ user.username, "user:#{user.id}" ] }
    name_options = name_labels(organization)
      .sort_by { |_key, label| label }
      .map { |key, label| [ "#{label} (sem cadastro)", key ] }

    user_options + name_options + [ [ Sale::UNLINKED_SELLER_NAME, UNLINKED ] ]
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

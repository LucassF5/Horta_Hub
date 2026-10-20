# frozen_string_literal: true

# Busca e ordenação pedidas por uma listagem. A ordenação só aceita as colunas
# declaradas pelo controller, então parâmetros desconhecidos voltam ao padrão.
class Listing
  DIRECTIONS = %w[asc desc].freeze

  attr_reader :query, :sort, :direction

  # Coluna de texto ordenada sem diferenciar maiúsculas de minúsculas.
  def self.case_insensitive(column)
    Arel::Nodes::NamedFunction.new("LOWER", [ column ])
  end

  def initialize(params, columns:, default_sort:, default_direction: "asc")
    @columns = columns
    @query = params[:q].to_s.squish
    @sort = columns.key?(params[:sort].to_s) ? params[:sort].to_s : default_sort
    @direction = DIRECTIONS.include?(params[:direction].to_s) ? params[:direction].to_s : default_direction
  end

  def apply(scope)
    scope.reorder(@columns.fetch(sort).public_send(direction), scope.arel_table[:id].public_send(direction))
  end

  def search?
    query.present?
  end

  def sorted_by?(column)
    sort == column
  end

  # Parâmetros do link de uma coluna: a coluna ativa alterna a direção, as demais começam em asc.
  def sort_params(column)
    direction = sorted_by?(column) && self.direction == "asc" ? "desc" : "asc"
    { q: query.presence, sort: column, direction: direction }.compact
  end

  def to_params
    { q: query.presence, sort: sort, direction: direction }.compact
  end
end

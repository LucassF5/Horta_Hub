# frozen_string_literal: true

# Dados de um registro em pares rótulo/valor. Valor vazio aparece como "-"; item nil é omitido.
class Components::DetailList < Components::Base
  def initialize(items:)
    @items = items
  end

  def view_template
    dl(class: "grid grid-cols-2 gap-x-4 gap-y-5 sm:grid-cols-3 lg:grid-cols-2") do
      @items.compact.each do |label, value|
        div(class: "min-w-0") do
          dt(class: "text-sm text-gray-500") { label }
          dd(class: "mt-1 break-words font-medium text-gray-900") { value.presence || "-" }
        end
      end
    end
  end
end

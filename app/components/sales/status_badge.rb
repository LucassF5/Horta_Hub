# frozen_string_literal: true

class Components::Sales::StatusBadge < Components::Base
  STATUSES = {
    "completed" => [ "Concluída", "bg-green-100 text-green-700" ],
    "pending" => [ "Pendente", "bg-yellow-100 text-yellow-700" ],
    "cancelled" => [ "Cancelada", "bg-red-100 text-red-700" ]
  }.freeze

  def initialize(status:)
    @status = status
  end

  def view_template
    label, classes = STATUSES.fetch(@status)

    span(class: "inline-flex whitespace-nowrap rounded-full px-2 py-1 text-xs font-medium #{classes}") { label }
  end
end

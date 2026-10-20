# frozen_string_literal: true

class Components::Listings::EmptyState < Components::Base
  def initialize(icon:, title:, description:)
    @icon = icon
    @title = title
    @description = description
  end

  def view_template(&actions)
    div(class: "flex flex-col items-center rounded-lg border border-dashed border-gray-300 bg-white px-6 py-12 text-center") do
      span(class: "flex size-12 items-center justify-center rounded-full bg-green-50 text-green-700") do
        render @icon.new(class: "size-6", aria: { hidden: true })
      end
      h2(class: "mt-4 text-base font-semibold text-gray-900") { @title }
      p(class: "mt-1 max-w-sm text-sm text-gray-600") { @description }
      div(class: "mt-6 flex flex-wrap justify-center gap-2", &actions) if actions
    end
  end
end

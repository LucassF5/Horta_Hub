# frozen_string_literal: true

class Components::PageHeader < Components::Base
  # back: [rótulo, caminho] da página de origem, exibido acima do título.
  def initialize(title:, description: nil, back: nil)
    @title = title
    @description = description
    @back = back
  end

  def view_template(&actions)
    div(class: "mb-6") do
      render_back_link if @back

      div(class: "flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between") do
        div(class: "min-w-0") do
          h1(class: "break-words text-2xl font-bold tracking-tight text-gray-900 sm:text-3xl") { @title }
          p(class: "mt-1 text-sm text-gray-600") { @description } if @description
        end

        div(class: "flex flex-wrap gap-2", &actions) if actions
      end
    end
  end

  private

  def render_back_link
    label, href = @back

    a(
      href: href,
      class: [
        "-ml-1 mb-2 inline-flex items-center gap-1 rounded px-1 py-0.5 text-sm font-medium text-gray-600",
        "hover:text-gray-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
      ]
    ) do
      render PhlexIcons::Lucide::ChevronLeft.new(class: "size-4", aria: { hidden: true })
      plain label
    end
  end
end

# frozen_string_literal: true

# Cabeçalho de tabela que ordena a listagem pela coluna ao ser clicado.
class Components::Listings::SortableHead < Components::Base
  def initialize(label:, column:, listing:, href:, **attrs)
    @label = label
    @column = column
    @listing = listing
    @href = href
    @attrs = attrs
  end

  def view_template
    render RubyUI::TableHead.new(aria: { sort: aria_sort }, **@attrs) do
      a(
        href: @href,
        data: { turbo_frame: "_top" },
        class: [
          "-mx-1 inline-flex items-center gap-1 rounded px-1 py-0.5 hover:text-foreground",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
          ("text-foreground" if active?)
        ]
      ) do
        plain @label
        render sort_icon.new(class: [ "size-3.5 shrink-0", ("opacity-50" unless active?) ], aria: { hidden: true })
      end
    end
  end

  private

  def active?
    @listing.sorted_by?(@column)
  end

  def aria_sort
    return "none" unless active?

    @listing.direction == "asc" ? "ascending" : "descending"
  end

  def sort_icon
    return PhlexIcons::Lucide::ArrowUpDown unless active?

    @listing.direction == "asc" ? PhlexIcons::Lucide::ArrowUp : PhlexIcons::Lucide::ArrowDown
  end
end

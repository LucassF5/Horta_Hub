# frozen_string_literal: true

# Campo de busca de listagens simples; preserva a ordenação atual ao buscar.
class Components::Listings::SearchForm < Components::Base
  def initialize(url:, listing:, label:, placeholder:)
    @url = url
    @listing = listing
    @label = label
    @placeholder = placeholder
  end

  def view_template
    form(action: @url, method: "get", role: "search", class: "flex w-full gap-2 sm:max-w-md") do
      input(type: "hidden", name: "sort", value: @listing.sort)
      input(type: "hidden", name: "direction", value: @listing.direction)

      div(class: "relative min-w-0 flex-1") do
        label(for: "q", class: "sr-only") { @label }
        render PhlexIcons::Lucide::Search.new(class: "pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground", aria: { hidden: true })
        render RubyUI::Input.new(type: :search, id: "q", name: "q", value: @listing.query, placeholder: @placeholder, autocomplete: "off", class: "bg-white pl-9")
      end

      render RubyUI::Button.new(type: :submit, variant: :outline) { "Buscar" }
    end
  end
end

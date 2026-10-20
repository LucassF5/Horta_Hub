# frozen_string_literal: true

class Views::Products::Index < Views::Base
  def initialize(products:, listing:)
    @products = products
    @listing = listing
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      render Components::PageHeader.new(title: "Produtos", description: "Itens que a organização vende e o preço padrão de cada um.") do
        # No primeiro uso o estado vazio já oferece o cadastro.
        render RubyUI::Link.new(href: new_product_path, variant: :primary) { "Novo Produto" } if allowed_to?(:create?, Product) && !first_use?
      end

      render_content
    end
  end

  private

  def first_use?
    @products.empty? && !@listing.search?
  end

  def render_content
    if first_use?
      render_empty_state
    else
      render_toolbar
      @products.empty? ? render_no_results : render_table
    end
  end

  def render_toolbar
    div(class: "mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between") do
      render Components::Listings::SearchForm.new(
        url: products_path,
        listing: @listing,
        label: "Buscar produtos",
        placeholder: "Nome do produto"
      )
      p(class: "text-sm text-gray-600") { pluralize(@products.size, "produto", plural: "produtos") } if @products.any?
    end
  end

  def render_table
    div(class: "rounded-lg border bg-white") do
      render RubyUI::Table.new do
        render RubyUI::TableHeader.new do
          render RubyUI::TableRow.new do
            sortable_head("Nome", "name", class: "pl-4")
            sortable_head("Preço", "price", class: "text-right")
            render RubyUI::TableHead.new(class: "pr-4 text-right") { span(class: "sr-only") { "Ações" } }
          end
        end

        render RubyUI::TableBody.new do
          @products.each { |product| render_product_row(product) }
        end
      end
    end
  end

  def sortable_head(label, column, **attrs)
    render Components::Listings::SortableHead.new(
      label: label,
      column: column,
      listing: @listing,
      href: products_path(@listing.sort_params(column)),
      **attrs
    )
  end

  def render_product_row(product)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new(class: "pl-4 font-medium text-gray-900") do
        a(href: product_path(product), class: "hover:underline") { product.name }
      end
      render RubyUI::TableCell.new(class: "text-right tabular-nums") { number_to_currency(product.price) }
      render RubyUI::TableCell.new(class: "pr-4") do
        render Components::Listings::RowActions.new(
          record: product,
          show_path: product_path(product),
          edit_path: edit_product_path(product),
          destroy_path: product_path(product),
          confirm: "Tem certeza que deseja apagar este produto?"
        )
      end
    end
  end

  def render_no_results
    render Components::Listings::EmptyState.new(
      icon: PhlexIcons::Lucide::SearchX,
      title: "Nenhum produto encontrado",
      description: "Nenhum produto tem \"#{@listing.query}\" no nome. Confira a grafia ou busque por outro termo."
    ) do
      render RubyUI::Link.new(href: products_path, variant: :outline) { "Limpar busca" }
    end
  end

  def render_empty_state
    if allowed_to?(:create?, Product)
      render Components::Listings::EmptyState.new(
        icon: PhlexIcons::Lucide::Package,
        title: "Cadastre o primeiro produto",
        description: "Com os produtos cadastrados, você monta as vendas escolhendo os itens e o preço já vem preenchido."
      ) do
        render RubyUI::Link.new(href: new_product_path, variant: :primary) { "Novo Produto" }
      end
    else
      render Components::Listings::EmptyState.new(
        icon: PhlexIcons::Lucide::Package,
        title: "Nenhum produto cadastrado",
        description: "Os produtos cadastrados pela equipe da organização aparecem aqui."
      )
    end
  end
end

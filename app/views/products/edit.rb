# frozen_string_literal: true

class Views::Products::Edit < Views::Base
  def initialize(product:)
    @product = product
  end

  def view_template
    div(class: "mt-8 mx-auto bg-background flex flex-col justify-center items-center") do
      div(class: "container mx-auto px-4 py-8") do
        h1(class: "text-3xl font-bold text-gray-800 mb-8") { "Editar Produto" }

        render_errors if @product.errors.any?
      end

      render Views::Products::FormComponent.new(
        product: @product,
        url: product_path(@product)
      )
    end
  end

  private

  def render_errors
    render RubyUI::Alert.new(variant: :destructive) do
      div do
        h2(class: "font-bold mb-2") do
          "#{pluralize(@product.errors.count, "erro")} impediram o produto de ser salvo:"
        end
        ul(class: "list-disc list-inside") do
          @product.errors.full_messages.each do |message|
            li { message }
          end
        end
      end
    end
  end
end

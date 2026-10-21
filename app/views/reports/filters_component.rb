# frozen_string_literal: true

class Views::Reports::FiltersComponent < Views::Base
  COMPARISON_OPTIONS = [
    [ "Mês anterior", "previous" ],
    [ "Mês atual", "current" ]
  ].freeze

  def initialize(report:)
    @report = report
  end

  def view_template
    form_with(
      url: report_path,
      method: :get,
      local: true,
      class: "mb-6 grid grid-cols-2 gap-3 rounded-lg border bg-white p-4 sm:gap-4 lg:grid-cols-4",
      data: { controller: "submit-on-change", action: "change->submit-on-change#submit" }
    ) do
      render_month_field
      render_comparison_field
      render_product_field
      render_seller_field

      div(class: "col-span-2 flex items-end justify-end gap-2 lg:col-span-4") do
        render RubyUI::Link.new(href: report_path, variant: :outline) { "Limpar" }
        render RubyUI::Button.new(type: :submit, class: "h-9") { "Aplicar" }
      end
    end
  end

  private

  attr_reader :report

  def render_month_field
    render RubyUI::FormField.new(class: "min-w-0") do
      render RubyUI::FormFieldLabel.new(for: "month") { "Mês" }
      select(id: "month", name: "month", class: input_classes) do
        report.month_options.each do |month|
          option(value: month.strftime("%Y-%m"), selected: month == report.period.month) { I18n.l(month, format: "%B de %Y") }
        end
      end
    end
  end

  def render_comparison_field
    render RubyUI::FormField.new(class: "min-w-0") do
      render RubyUI::FormFieldLabel.new(for: "comparison") { "Comparar com" }
      select(id: "comparison", name: "comparison", class: input_classes) do
        COMPARISON_OPTIONS.each do |label, value|
          option(value: value, selected: report.period.comparison.to_s == value) { label }
        end
      end
    end
  end

  def render_product_field
    render RubyUI::FormField.new(class: "min-w-0") do
      render RubyUI::FormFieldLabel.new(for: "product_id") { "Produto" }
      select(id: "product_id", name: "product_id", class: input_classes) do
        option(value: "", selected: report.product.nil?) { "Todos" }
        report.product_options.each do |product|
          option(value: product.id, selected: report.product&.id == product.id) { product.name }
        end
      end
    end
  end

  def render_seller_field
    render RubyUI::FormField.new(class: "min-w-0") do
      render RubyUI::FormFieldLabel.new(for: "seller") { "Vendedor" }
      select(id: "seller", name: "seller", class: input_classes) do
        option(value: "", selected: report.seller_key.nil?) { "Todos" }
        report.seller_options.each do |label, key|
          option(value: key, selected: report.seller_key == key) { label }
        end
      end
    end
  end

  def input_classes
    [
      "flex h-9 w-full min-w-0 rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "placeholder:text-muted-foreground",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end

# frozen_string_literal: true

class Views::ImportBatches::New < Views::Base
  def initialize(import_batch:)
    @import_batch = import_batch
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      h1(class: "mb-6 text-3xl font-bold text-gray-800") { "Nova Importação" }
      render_errors if @import_batch.errors.any?
      render_form
    end
  end

  private

  def render_form
    form_with(model: @import_batch, local: true, class: "max-w-xl rounded-md border bg-white p-6 shadow-sm") do |form|
      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "import_batch_file") { "Arquivo XLSX" }
        form.file_field(:file, id: "import_batch_file", accept: ".xlsx", class: input_classes)
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: "import_batch_year") { "Ano" }
        form.number_field(:year, id: "import_batch_year", value: @import_batch.year || Date.current.year, class: input_classes)
      end

      div(class: "mt-6 flex items-center gap-3") do
        render RubyUI::Button.new(type: :submit) { "Importar" }
        render RubyUI::Link.new(href: import_batches_path, variant: :outline) { "Cancelar" }
      end
    end
  end

  def render_errors
    render RubyUI::Alert.new(variant: :destructive, class: "mb-6") do
      div do
        h2(class: "mb-2 font-bold") { "Não foi possível iniciar a importação:" }
        ul(class: "list-inside list-disc") do
          @import_batch.errors.full_messages.each { |message| li { message } }
        end
      end
    end
  end

  def input_classes
    [
      "flex min-h-9 w-full rounded-md border bg-background px-3 py-2 text-sm shadow-xs",
      "border-border focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2"
    ].join(" ")
  end
end

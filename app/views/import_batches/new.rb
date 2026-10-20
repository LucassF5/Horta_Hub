# frozen_string_literal: true

class Views::ImportBatches::New < Views::Base
  def initialize(import_batch:)
    @import_batch = import_batch
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div(class: "max-w-2xl") do
        render Components::PageHeader.new(
          title: "Nova Importação",
          description: "Envie a planilha XLSX de vendas do ano. Ela é processada em segundo plano e removida ao final.",
          back: [ "Voltar para importações", import_batches_path ]
        )
        render_errors if @import_batch.errors.any?
        render_form
      end
    end
  end

  private

  def render_form
    form_with(model: @import_batch, local: true) do |form|
      render Components::Forms::Card.new(submit_label: "Importar", cancel_href: import_batches_path) do
        div(class: "grid gap-5 sm:grid-cols-[minmax(0,3fr)_minmax(0,1fr)]") do
          render RubyUI::FormField.new(class: "min-w-0") do
            render RubyUI::FormFieldLabel.new(for: "import_batch_file") { "Arquivo XLSX" }
            form.file_field(:file, id: "import_batch_file", accept: ".xlsx", class: input_classes)
          end

          render RubyUI::FormField.new(class: "min-w-0") do
            render RubyUI::FormFieldLabel.new(for: "import_batch_year") { "Ano" }
            form.number_field(:year, id: "import_batch_year", value: @import_batch.year || Date.current.year, inputmode: "numeric", class: input_classes)
          end
        end
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

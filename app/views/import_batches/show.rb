# frozen_string_literal: true

class Views::ImportBatches::Show < Views::Base
  def initialize(import_batch:)
    @import_batch = import_batch
  end

  def view_template
    div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8") do
      div(class: "max-w-4xl") do
        render Components::PageHeader.new(
          title: "Importação ##{@import_batch.id}",
          description: @import_batch.file_name,
          back: [ "Voltar para importações", import_batches_path ]
        )

        render Views::ImportBatches::Progress.new(import_batch: @import_batch)
      end
    end
  end
end

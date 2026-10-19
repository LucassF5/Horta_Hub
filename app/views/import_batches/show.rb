# frozen_string_literal: true

class Views::ImportBatches::Show < Views::Base
  def initialize(import_batch:)
    @import_batch = import_batch
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      div(class: "mb-6 flex items-center justify-between") do
        h1(class: "text-3xl font-bold text-gray-800") { "Importação ##{@import_batch.id}" }
        render RubyUI::Link.new(href: import_batches_path, variant: :outline) { "Voltar" }
      end

      render Views::ImportBatches::Progress.new(import_batch: @import_batch)
    end
  end
end

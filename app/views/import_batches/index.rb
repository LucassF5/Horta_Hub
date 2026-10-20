# frozen_string_literal: true

class Views::ImportBatches::Index < Views::Base
  def initialize(import_batches:)
    @import_batches = import_batches
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      render_header

      if @import_batches.empty?
        p(class: "text-gray-600") { "Nenhuma importação encontrada." }
      else
        render_table
      end
    end
  end

  private

  def render_header
    div(class: "mb-6 flex items-center justify-between") do
      h1(class: "text-3xl font-bold text-gray-800") { "Importações" }
      render RubyUI::Link.new(href: new_import_batch_path, variant: :primary) { "Nova Importação" } if allowed_to?(:create?, ImportBatch)
    end
  end

  def render_table
    render RubyUI::Table.new do
      render RubyUI::TableHeader.new do
        render RubyUI::TableRow.new do
          render RubyUI::TableHead.new { "Arquivo" }
          render RubyUI::TableHead.new { "Ano" }
          render RubyUI::TableHead.new { "Status" }
          render RubyUI::TableHead.new { "Processadas" }
          render RubyUI::TableHead.new { "Falhas" }
          render RubyUI::TableHead.new(class: "text-right") { "Ações" }
        end
      end

      render RubyUI::TableBody.new do
        @import_batches.each { |import_batch| render_import_batch_row(import_batch) }
      end
    end
  end

  def render_import_batch_row(import_batch)
    render RubyUI::TableRow.new do
      render RubyUI::TableCell.new { import_batch.file_name }
      render RubyUI::TableCell.new { import_batch.year.to_s }
      render RubyUI::TableCell.new { status_label(import_batch) }
      render RubyUI::TableCell.new { "#{import_batch.processed_rows}/#{import_batch.total_rows}" }
      render RubyUI::TableCell.new { import_batch.failed_rows.to_s }
      render RubyUI::TableCell.new(class: "text-right") do
        render RubyUI::Link.new(href: import_batch_path(import_batch), variant: :outline) { "Ver" }
      end
    end
  end

  def status_label(import_batch)
    case import_batch.status
    when "pending" then "Pendente"
    when "processing" then "Processando"
    when "completed" then "Concluída"
    when "failed" then "Falhou"
    end
  end
end

class SalesImportJob < ApplicationJob
  queue_as :default

  # Limite para o conteúdo descompactado do XLSX (proteção contra zip bomb).
  MAX_UNCOMPRESSED_SIZE = 50.megabytes

  def perform(import_batch)
    # Reprocessar um lote duplicaria as vendas já criadas.
    return unless import_batch.pending?

    import_batch.update!(
      status: :processing,
      started_at: Time.current
    )

    import_batch.file.open do |file|
      Imports::SalesSpreadsheetImporter.new(
        import_batch: import_batch,
        spreadsheet: open_spreadsheet(file.path)
      ).call
    end

    import_batch.update!(
      status: :completed,
      finished_at: Time.current
    )
  rescue Imports::SalesSpreadsheetImporter::Error => error
    fail_import(import_batch, error.message)
  rescue => error
    fail_import(import_batch, "Erro inesperado ao processar a importação.")

    raise
  end

  private

  def open_spreadsheet(path)
    uncompressed_size = Zip::File.open(path) { |zip| zip.entries.sum(&:size) }
    if uncompressed_size > MAX_UNCOMPRESSED_SIZE
      raise Imports::SalesSpreadsheetImporter::Error, "Arquivo XLSX muito grande para processar."
    end

    Roo::Spreadsheet.open(path, extension: :xlsx)
  rescue Zip::Error
    raise Imports::SalesSpreadsheetImporter::Error, "Arquivo XLSX inválido ou corrompido."
  end

  def fail_import(import_batch, message)
    import_batch.update!(
      status: :failed,
      finished_at: Time.current
    )
    import_batch.add_error_detail(row: nil, message: message)
  end
end

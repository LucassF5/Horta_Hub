namespace :import_batches do
  desc "Remove as planilhas de lotes de importação já finalizados"
  task purge_files: :environment do
    ImportBatch.where(status: %i[completed failed]).with_attached_file.find_each(&:purge_file)
  end
end

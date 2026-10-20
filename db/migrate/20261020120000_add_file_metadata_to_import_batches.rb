class AddFileMetadataToImportBatches < ActiveRecord::Migration[8.1]
  def up
    add_column :import_batches, :file_name, :string
    add_column :import_batches, :file_checksum, :string

    # Copia os dados do blob para o lote antes que as planilhas sejam removidas.
    execute <<~SQL
      UPDATE import_batches
      SET file_name = active_storage_blobs.filename,
          file_checksum = active_storage_blobs.checksum
      FROM active_storage_attachments
      JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id
      WHERE active_storage_attachments.record_type = 'ImportBatch'
        AND active_storage_attachments.name = 'file'
        AND active_storage_attachments.record_id = import_batches.id
    SQL

    add_index :import_batches, [ :organization_id, :file_checksum ]
  end

  def down
    remove_index :import_batches, [ :organization_id, :file_checksum ]
    remove_column :import_batches, :file_checksum
    remove_column :import_batches, :file_name
  end
end

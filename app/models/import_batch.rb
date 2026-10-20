class ImportBatch < ApplicationRecord
  XLSX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  MAX_FILE_SIZE = 5.megabytes

  belongs_to :organization
  belongs_to :user

  has_one_attached :file

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }

  before_validation :store_file_metadata, on: :create

  # A planilha só é obrigatória no envio: SalesImportJob a remove ao final.
  validates :file, presence: true, on: :create
  validates :status, presence: true
  validates :year, presence: true,
                   numericality: { only_integer: true, greater_than_or_equal_to: 2000, less_than_or_equal_to: 2100 }
  validate :file_must_be_xlsx
  validate :file_must_not_be_already_imported, on: :create

  def add_error_detail(row:, message:)
    update!(error_details: error_details + [ { "row" => row, "message" => message } ])
  end

  def running?
    pending? || processing?
  end

  # Nome e checksum ficam no lote para manter o histórico e o bloqueio de
  # reimportação depois que o arquivo é apagado.
  def purge_file
    file.purge if file.attached?
  end

  private

  def store_file_metadata
    return unless file.attached?

    self.file_name = file.filename.to_s
    self.file_checksum = file.blob.checksum
  end

  def file_must_be_xlsx
    return unless file.attached?

    unless file.filename.extension.casecmp?("xlsx") && file.content_type == XLSX_CONTENT_TYPE
      errors.add(:file, "deve ser uma planilha .xlsx")
    end

    errors.add(:file, "deve ter no máximo 5 MB") if file.byte_size > MAX_FILE_SIZE
  end

  # Reenviar uma planilha já importada duplicaria todas as vendas.
  def file_must_not_be_already_imported
    return unless file.attached? && organization

    already_imported = organization.import_batches
      .where(file_checksum: file_checksum)
      .where("import_batches.status != ? OR import_batches.successful_rows > 0", "failed")
      .exists?

    errors.add(:file, "já foi importado nesta organização") if already_imported
  end
end

# == Schema Information
#
# Table name: import_batches
#
#  id              :integer          not null, primary key
#  error_details   :json             not null
#  failed_rows     :integer          default(0), not null
#  file_checksum   :string
#  file_name       :string
#  finished_at     :datetime
#  processed_rows  :integer          default(0), not null
#  started_at      :datetime
#  status          :string           default("pending"), not null
#  successful_rows :integer          default(0), not null
#  total_rows      :integer          default(0), not null
#  year            :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_import_batches_on_organization_id                    (organization_id)
#  index_import_batches_on_organization_id_and_file_checksum  (organization_id,file_checksum)
#  index_import_batches_on_user_id                            (user_id)
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#  user_id          (user_id => users.id)
#

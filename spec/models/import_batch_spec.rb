require 'rails_helper'

RSpec.describe ImportBatch, type: :model do
  describe "associations" do
    it { should belong_to(:organization) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:year) }

    it "requires an attached file" do
      import_batch = build(:import_batch)
      import_batch.file.detach

      expect(import_batch).not_to be_valid
      expect(import_batch.errors[:file]).to be_present
    end
  end

  describe "file and year validations" do
    it "rejects files that are not XLSX" do
      import_batch = build(:import_batch)
      import_batch.file.attach(io: StringIO.new("<script></script>"), filename: "evil.html", content_type: "text/html")

      expect(import_batch).not_to be_valid
      expect(import_batch.errors[:file]).to include("deve ser uma planilha .xlsx")
    end

    it "rejects files larger than the limit" do
      stub_const("ImportBatch::MAX_FILE_SIZE", 5)
      import_batch = build(:import_batch)

      expect(import_batch).not_to be_valid
      expect(import_batch.errors[:file]).to include("deve ter no máximo 5 MB")
    end

    it "rejects years outside the accepted range" do
      expect(build(:import_batch, year: 1999)).not_to be_valid
      expect(build(:import_batch, year: 2101)).not_to be_valid
      expect(build(:import_batch, year: 2026)).to be_valid
    end

    it "rejects a file already imported in the same organization" do
      existing = create(:import_batch, status: :completed)
      duplicate = build(:import_batch, organization: existing.organization)
      duplicate.file.attach(io: StringIO.new(existing.file.download), filename: "copia.xlsx",
                            content_type: ImportBatch::XLSX_CONTENT_TYPE)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:file]).to include("já foi importado nesta organização")
    end

    it "allows the same file again after a failed import that created nothing" do
      existing = create(:import_batch, status: :failed, successful_rows: 0)
      retry_batch = build(:import_batch, organization: existing.organization)
      retry_batch.file.attach(io: StringIO.new(existing.file.download), filename: "copia.xlsx",
                              content_type: ImportBatch::XLSX_CONTENT_TYPE)

      expect(retry_batch).to be_valid
    end

    it "allows the same file in another organization" do
      existing = create(:import_batch, status: :completed)
      other = build(:import_batch)
      other.file.attach(io: StringIO.new(existing.file.download), filename: "copia.xlsx",
                        content_type: ImportBatch::XLSX_CONTENT_TYPE)

      expect(other).to be_valid
    end
  end

  describe "#add_error_detail" do
    it "appends an error detail" do
      import_batch = create(:import_batch)

      import_batch.add_error_detail(row: 3, message: "Status inválido")

      expect(import_batch.reload.error_details).to include(
        "row" => 3,
        "message" => "Status inválido"
      )
    end
  end
end

# == Schema Information
#
# Table name: import_batches
#
#  id              :integer          not null, primary key
#  error_details   :json             not null
#  failed_rows     :integer          default(0), not null
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
#  index_import_batches_on_organization_id  (organization_id)
#  index_import_batches_on_user_id          (user_id)
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#  user_id          (user_id => users.id)
#

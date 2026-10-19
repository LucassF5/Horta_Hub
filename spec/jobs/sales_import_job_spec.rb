require 'rails_helper'

RSpec.describe SalesImportJob, type: :job do
  def import_batch_with_fixture
    create(:import_batch, year: 2026).tap do |import_batch|
      import_batch.file.attach(
        io: file_fixture("sales_import.xlsx").open,
        filename: "sales_import.xlsx",
        content_type: ImportBatch::XLSX_CONTENT_TYPE
      )
    end
  end

  it "imports a real spreadsheet and marks the import as completed" do
    import_batch = import_batch_with_fixture

    described_class.perform_now(import_batch)

    expect(import_batch.reload).to be_completed
    expect(import_batch).to have_attributes(total_rows: 3, successful_rows: 3, failed_rows: 0)
    expect(import_batch.started_at).to be_present
    expect(import_batch.finished_at).to be_present

    sales = import_batch.organization.sales.order(:sale_date)
    expect(sales.map(&:sale_date)).to eq([ Date.new(2026, 10, 2), Date.new(2026, 10, 4) ])
    expect(sales.first.sale_items.count).to eq(2)
    expect(sales.first.total).to eq(100)
    expect(sales.last).to have_attributes(status: "pending", notes: "Cliente solicitou prazo")
  end

  it "does not process an import that is no longer pending" do
    import_batch = import_batch_with_fixture
    import_batch.update!(status: :completed)

    described_class.perform_now(import_batch)

    expect(import_batch.organization.sales).to be_empty
  end

  it "marks the import as failed with a clear message when the file is not a valid XLSX" do
    import_batch = create(:import_batch)

    described_class.perform_now(import_batch)

    expect(import_batch.reload).to be_failed
    expect(import_batch.error_details).to include(
      "row" => nil,
      "message" => "Arquivo XLSX inválido ou corrompido."
    )
  end

  it "rejects archives whose uncompressed content exceeds the limit" do
    stub_const("SalesImportJob::MAX_UNCOMPRESSED_SIZE", 100)
    import_batch = import_batch_with_fixture

    described_class.perform_now(import_batch)

    expect(import_batch.reload).to be_failed
    expect(import_batch.error_details.last["message"]).to eq("Arquivo XLSX muito grande para processar.")
    expect(import_batch.organization.sales).to be_empty
  end

  it "marks the import as failed without exposing internal errors" do
    import_batch = import_batch_with_fixture

    allow(Roo::Spreadsheet).to receive(:open).and_raise("SQLite3::BusyException: database is locked")

    expect {
      described_class.perform_now(import_batch)
    }.to raise_error(RuntimeError)

    expect(import_batch.reload).to be_failed
    expect(import_batch.error_details).to include(
      "row" => nil,
      "message" => "Erro inesperado ao processar a importação."
    )
  end
end

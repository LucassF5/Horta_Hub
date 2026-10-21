require "rails_helper"

RSpec.describe Imports::SalesSpreadsheetImporter do
  class FakeSpreadsheet
    def initialize(rows)
      @rows = rows
    end

    def sheet(_index)
      self
    end

    def row(number)
      @rows.fetch(number - 1)
    end

    def cell(row_number, column_number)
      @rows.dig(row_number - 1, column_number - 1)
    end

    def last_row
      @rows.size
    end
  end

  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:import_batch) { create(:import_batch, organization: organization, user: user, year: 2026) }

  let(:headers) do
    [ "DIA", "DATA", "CLIENTE", "PRODUTO", "QTD", "VALOR", "RESPONSÁVEL", "STATUS", "OBSERVAÇÃO" ]
  end

  def importer_for(rows)
    described_class.new(
      import_batch: import_batch,
      spreadsheet: FakeSpreadsheet.new([ headers, *rows ])
    )
  end

  it "imports grouped sales with one item per spreadsheet row" do
    importer_for([
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 15, "R$ 60,00", "LUCAS", "PG", nil ],
      [ "QUINTA", "02/10/2026", "AGROVALE", "CHEIRO VERDE", 10, "R$ 40,00", "LUCAS", "PG", nil ]
    ]).call

    sale = organization.sales.sole
    expect(sale.client.name).to eq("AGROVALE")
    expect(sale.sale_date).to eq(Date.new(2026, 10, 2))
    expect(sale.responsible_name).to eq("LUCAS")
    expect(sale.status).to eq("completed")
    expect(sale.total).to eq(100)
    expect(sale.sale_items.count).to eq(2)
    expect(sale.sale_items.map(&:unit_price)).to contain_exactly(4, 4)

    expect(organization.clients.count).to eq(1)
    expect(organization.products.pluck(:name)).to contain_exactly("Alface", "Cheiro Verde")
    expect(import_batch.reload).to have_attributes(
      total_rows: 2,
      processed_rows: 2,
      successful_rows: 2,
      failed_rows: 0
    )
  end

  it "uses import batch year when the date omits the year" do
    importer_for([
      [ "QUINTA", "02/10", "AGROVALE", "ALFACE", 15, "60,00", "LUCAS", "PG", nil ]
    ]).call

    expect(organization.sales.sole.sale_date).to eq(Date.new(2026, 10, 2))
  end

  it "maps pending status and preserves notes" do
    importer_for([
      [ "SÁBADO", "04/10/2026", "SACOLÃO POPULAR", "ALFACE", 35, "R$ 140,00", "JR", "PENDENTE", "Cliente solicitou prazo" ]
    ]).call

    sale = organization.sales.sole
    expect(sale.status).to eq("pending")
    expect(sale.notes).to eq("Cliente solicitou prazo")
  end

  it "records invalid rows without stopping valid rows" do
    importer_for([
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 15, "R$ 60,00", "LUCAS", "PG", nil ],
      [ "SEXTA", "03/10/2026", "AGROVALE", "ALFACE", 0, "R$ 60,00", "LUCAS", "PG", nil ]
    ]).call

    expect(organization.sales.count).to eq(1)
    expect(import_batch.reload).to have_attributes(
      total_rows: 2,
      processed_rows: 2,
      successful_rows: 1,
      failed_rows: 1
    )
    expect(import_batch.error_details).to include(
      "row" => 3,
      "message" => "Quantidade deve ser maior que zero"
    )
  end

  it "accepts month abbreviations without year" do
    importer_for([
      [ "QUINTA", "02/out", "AGROVALE", "ALFACE", 15, "60,00", "LUCAS", "PG", nil ]
    ]).call

    expect(organization.sales.sole.sale_date).to eq(Date.new(2026, 10, 2))
  end

  it "accepts Excel date and numeric cells" do
    importer_for([
      [ "QUINTA", Date.new(2026, 10, 2), "AGROVALE", "ALFACE", 15.0, 60.5, "LUCAS", "PG", nil ]
    ]).call

    item = organization.sales.sole.sale_items.sole
    expect(item.quantity).to eq(15)
    expect(item.unit_price).to eq(BigDecimal("4.03"))
  end

  it "parses Brazilian and dot decimal money formats" do
    importer_for([
      [ "QUINTA", "02/10/2026", "CLIENTE A", "ALFACE", 1, "R$ 1.234,56", "LUCAS", "PG", nil ],
      [ "QUINTA", "02/10/2026", "CLIENTE B", "ALFACE", 1, "60.50", "LUCAS", "PG", nil ]
    ]).call

    expect(organization.sales.order(:id).map(&:total)).to eq([ BigDecimal("1234.56"), BigDecimal("60.50") ])
  end

  it "rejects fractional quantities and non-positive numeric values" do
    importer_for([
      [ "QUINTA", "02/10/2026", "CLIENTE A", "ALFACE", 1.5, 60, "LUCAS", "PG", nil ],
      [ "QUINTA", "03/10/2026", "CLIENTE B", "ALFACE", 10, 0, "LUCAS", "PG", nil ],
      [ "QUINTA", "04/10/2026", "CLIENTE C", "ALFACE", 10, -60, "LUCAS", "PG", nil ]
    ]).call

    expect(organization.sales).to be_empty
    expect(import_batch.reload.error_details).to contain_exactly(
      { "row" => 2, "message" => "Quantidade deve ser um número inteiro: 1.5" },
      { "row" => 3, "message" => "Valor deve ser maior que zero" },
      { "row" => 4, "message" => "Valor deve ser maior que zero" }
    )
  end

  it "does not import a partial sale when one of its rows is invalid" do
    importer_for([
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 10, "50,00", "LUCAS", "PG", nil ],
      [ "QUINTA", "02/10/2026", "AGROVALE", "TOMATE", 10, "abc", "LUCAS", "PG", nil ]
    ]).call

    expect(organization.sales).to be_empty
    expect(import_batch.reload).to have_attributes(successful_rows: 0, failed_rows: 2)
    expect(import_batch.error_details).to contain_exactly(
      { "row" => 2, "message" => "Venda não importada: a(s) linha(s) 3 da mesma venda contém erros" },
      { "row" => 3, "message" => "Valor inválido: abc" }
    )
  end

  it "does not leave clients or products behind when the sale fails" do
    importer_for([
      [ "QUINTA", "02/10/2026", "CLIENTE NOVO", "AB", 1, "10,00", "LUCAS", "PG", nil ],
      [ "QUINTA", "03/10/2026", "CLIENTE NOVO", "ALFACE", 1, "10,00", "LUCAS", "PG", nil ]
    ]).call

    expect(import_batch.reload.error_details).to include(
      "row" => 2,
      "message" => "Produto \"AB\": Nome é muito curto (mínimo: 3 caracteres)"
    )
    expect(organization.clients.pluck(:name)).to eq([ "CLIENTE NOVO" ])
    expect(organization.sales.sole.sale_date).to eq(Date.new(2026, 10, 3))
  end

  it "reuses existing clients and products regardless of case and spacing" do
    client = create(:client, organization: organization, name: "Agrovale")
    product = create(:product, organization: organization, name: "Alface", price: 3)

    importer_for([
      [ "QUINTA", "02/10/2026", " agrovale ", "ALFACE", 15, "60,00", "LUCAS", "PG", nil ]
    ]).call

    sale = organization.sales.sole
    expect(sale.client).to eq(client)
    expect(sale.sale_items.sole.product).to eq(product)
    expect(organization.clients.count).to eq(1)
    expect(organization.products.count).to eq(1)
  end

  it "keeps the spreadsheet price as custom price without changing the existing product price" do
    product = create(:product, organization: organization, name: "Alface", price: 3)

    importer_for([
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 15, "60,00", "LUCAS", "PG", nil ]
    ]).call

    item = organization.sales.sole.sale_items.sole
    expect(item.unit_price).to eq(4)
    expect(item.custom_price).to be(true)
    expect(product.reload.price).to eq(3)
  end

  it "does not mark the item as custom price when the spreadsheet price matches the product price" do
    importer_for([
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 15, "60,00", "LUCAS", "PG", nil ]
    ]).call

    item = organization.sales.sole.sale_items.sole
    expect(item.unit_price).to eq(4)
    expect(item.custom_price).to be(false)
  end

  it "does not reuse clients or products from another organization" do
    other_organization = create(:organization)
    create(:client, organization: other_organization, name: "Agrovale")
    create(:product, organization: other_organization, name: "Alface")

    importer_for([
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 15, "60,00", "LUCAS", "PG", nil ]
    ]).call

    sale = organization.sales.sole
    expect(sale.client.organization).to eq(organization)
    expect(sale.sale_items.sole.product.organization).to eq(organization)
    expect(other_organization.sales).to be_empty
  end

  it "splits rows into separate sales when grouping fields differ" do
    importer_for([
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 1, "4,00", "LUCAS", "PG", nil ],
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 1, "4,00", "JR", "PG", nil ],
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 1, "4,00", "LUCAS", "PENDENTE", nil ]
    ]).call

    expect(organization.sales.count).to eq(3)
  end

  it "reports missing client and invalid status with the row number" do
    importer_for([
      [ "QUINTA", "02/10/2026", nil, "ALFACE", 1, "4,00", "LUCAS", "PG", nil ],
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 1, "4,00", "LUCAS", "FIADO", nil ]
    ]).call

    expect(import_batch.reload.error_details).to contain_exactly(
      { "row" => 2, "message" => "Cliente não informado" },
      { "row" => 3, "message" => "Status inválido: FIADO" }
    )
  end

  it "raises when the spreadsheet exceeds the row limit" do
    stub_const("Imports::SalesSpreadsheetImporter::MAX_ROWS", 1)

    importer = importer_for([
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 1, "4,00", "LUCAS", "PG", nil ],
      [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 1, "4,00", "LUCAS", "PG", nil ]
    ])

    expect { importer.call }.to raise_error(described_class::Error, /limite é 1/)
    expect(organization.sales).to be_empty
  end

  it "raises when required headers are missing" do
    spreadsheet = FakeSpreadsheet.new([
      [ "DATA", "CLIENTE" ],
      [ "02/10/2026", "AGROVALE" ]
    ])

    importer = described_class.new(import_batch: import_batch, spreadsheet: spreadsheet)

    expect { importer.call }.to raise_error(described_class::Error, /Cabeçalhos ausentes/)
  end

  def row(responsible)
    [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 15, "60,00", responsible, "PG", nil ]
  end

  it "links the sale to the member whose username matches RESPONSAVEL" do
    seller = create(:user, username: "Lucas")
    create(:membership, user: seller, organization: organization, role: "manager")
    importer_for([ row("LUCAS") ]).call
    expect(organization.sales.sole).to have_attributes(seller_id: seller.id, responsible_name: "LUCAS")
  end

  it "keeps only the name when RESPONSAVEL matches no member" do
    importer_for([ row("JOAO") ]).call
    expect(organization.sales.sole).to have_attributes(seller_id: nil, responsible_name: "JOAO")
  end

  it "keeps only the name when RESPONSAVEL matches more than one member" do
    %w[ana Ána].each { |username| create(:membership, user: create(:user, username: username), organization: organization, role: "manager") }
    importer_for([ row("ANA") ]).call
    expect(organization.sales.sole).to have_attributes(seller_id: nil, responsible_name: "ANA")
  end
end

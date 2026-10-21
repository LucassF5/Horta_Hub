require "rails_helper"

RSpec.describe Reports::ProductBreakdown do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }
  let(:maria) { create(:user).tap { |user| create(:membership, user: user, organization: organization, role: "manager") } }
  let(:products) do
    %w[Alface Rúcula Couve Cheiro\ Verde Pepino Tomate].index_with { |name| create(:product, organization: organization, name: name) }
  end

  def rows(product: nil, seller_key: nil)
    period = Reports::Period.new(month: Date.new(2026, 8, 1), comparison: "previous", today: today)
    scope = Reports::Scope.new(organization: organization, product: product, seller_key: seller_key)
    described_class.new(scope: scope, period: period).rows
  end

  before do
    p = products
    create_report_sale(organization: organization, date: Date.new(2026, 3, 10), items: [ [ p["Pepino"], 2, 5 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 5, 10), items: [ [ p["Couve"], 1, 4 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 7, 10), items: [ [ p["Alface"], 4, 2 ], [ p["Rúcula"], 5, 3 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 5), items: [ [ p["Alface"], 6, 2 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 10), seller: maria, items: [ [ p["Cheiro Verde"], 3, 1 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 12), items: [ [ p["Couve"], 1, 4 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 15), status: "pending", items: [ [ p["Tomate"], 1, 3 ] ])
  end

  it "lists every product ever sold, including the ones that stopped selling" do
    result = rows
    expect(result.map { |row| row.product.name }).to eq([ "Alface", "Cheiro Verde", "Couve", "Pepino", "Rúcula" ])
    expect(result.map(&:quantity)).to eq([ 6, 3, 1, 0, 0 ])
    expect(result.map(&:revenue)).to eq([ 12, 3, 4, 0, 0 ])
    expect(result.map(&:share)).to eq([ 63.2, 15.8, 21.1, 0.0, 0.0 ])
    expect(result.map(&:change)).to eq([ 50.0, nil, nil, nil, -100.0 ])
    expect(result.map(&:first_sold_in_month)).to eq([ false, true, false, false, false ])
  end

  it "keeps the product list with a seller filter and shows zeros" do
    result = rows(seller_key: "user:#{maria.id}")
    expect(result.map { |row| row.product.name }).to eq([ "Cheiro Verde", "Alface", "Couve", "Pepino", "Rúcula" ])
    expect(result.map(&:quantity)).to eq([ 3, 0, 0, 0, 0 ])
    expect(result.first.first_sold_in_month).to be(true)
  end

  it "shows only the filtered product" do
    expect(rows(product: products["Alface"]).map { |row| [ row.product.name, row.quantity ] }).to eq([ [ "Alface", 6 ] ])
  end
end

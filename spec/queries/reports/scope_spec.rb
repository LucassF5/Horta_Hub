require "rails_helper"

RSpec.describe Reports::Scope do
  let(:organization) { create(:organization) }
  let(:a) { create(:product, organization: organization) }
  let(:b) { create(:product, organization: organization) }
  let(:maria) { create(:user).tap { |user| create(:membership, user: user, organization: organization, role: "manager") } }
  let(:august) { Date.new(2026, 8, 1).all_month }

  before do
    create_report_sale(organization: organization, date: Date.new(2026, 8, 5), seller: maria, items: [ [ a, 2, 10 ], [ b, 1, 5 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 10), items: [ [ a, 1, 10 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 12), status: "pending", items: [ [ b, 4, 5 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 15), status: "cancelled", items: [ [ a, 1, 10 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 7, 30), items: [ [ a, 9, 10 ] ])
    other = create(:organization)
    create_report_sale(organization: other, date: Date.new(2026, 8, 5), items: [ [ create(:product, organization: other), 5, 100 ] ])
  end

  def totals(scope, status) = scope.totals(august).fetch(status).to_h

  it "totals each status in the range for the organization only" do
    scope = described_class.new(organization: organization)
    expect(totals(scope, "completed")).to eq(revenue: 35, sales_count: 2, units: 4)
    expect(totals(scope, "pending")).to eq(revenue: 20, sales_count: 1, units: 4)
    expect(totals(scope, "cancelled")).to eq(revenue: 10, sales_count: 1, units: 1)
  end

  it "filters by product" do
    scope = described_class.new(organization: organization, product: a)
    expect(totals(scope, "completed")).to eq(revenue: 30, sales_count: 2, units: 3)
    expect(totals(scope, "pending")).to eq(revenue: 0, sales_count: 0, units: 0)
  end

  it "filters by seller key" do
    expect(totals(described_class.new(organization: organization, seller_key: "user:#{maria.id}"), "completed")).to eq(revenue: 25, sales_count: 1, units: 3)
    expect(totals(described_class.new(organization: organization, seller_key: "none"), "completed")).to eq(revenue: 10, sales_count: 1, units: 1)
  end

  it "counts a sale once even with two items of the same product" do
    create_report_sale(organization: organization, date: Date.new(2026, 8, 20), items: [ [ a, 1, 10 ], [ a, 2, 10 ] ])
    expect(totals(described_class.new(organization: organization, product: a), "completed")).to eq(revenue: 60, sales_count: 3, units: 6)
  end

  it "computes the ticket" do
    expect(Reports::Scope::Totals.new(revenue: 35, sales_count: 2, units: 4).ticket).to eq(17.5)
    expect(Reports::Scope::Totals.zero.ticket).to be_nil
  end
end

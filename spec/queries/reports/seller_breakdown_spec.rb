require "rails_helper"

RSpec.describe Reports::SellerBreakdown do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }
  let(:a) { create(:product, organization: organization) }
  let!(:maria) { member("maria") }
  let!(:joao) { member("joao") }

  def member(username)
    create(:user, username: username).tap { |user| create(:membership, user: user, organization: organization, role: "manager") }
  end

  def sale(date, price, seller: nil, name: nil, status: "completed")
    create_report_sale(organization: organization, date: date, items: [ [ a, 1, price ] ], seller: seller, responsible_name: name, status: status)
  end

  def rows
    period = Reports::Period.new(month: Date.new(2026, 8, 1), comparison: "previous", today: today)
    described_class.new(scope: Reports::Scope.new(organization: organization), period: period).rows
  end

  before do
    sale(Date.new(2026, 7, 5), 20, seller: maria)
    sale(Date.new(2026, 7, 6), 10, name: "JOAO SILVA")
    sale(Date.new(2026, 8, 5), 10, seller: maria)
    sale(Date.new(2026, 8, 6), 20, seller: maria)
    sale(Date.new(2026, 8, 7), 15, name: "JOÃO SILVA")
    sale(Date.new(2026, 8, 8), 5, name: "Joao Silva")
    sale(Date.new(2026, 8, 9), 5)
    sale(Date.new(2026, 8, 10), 50, seller: maria, status: "pending")
  end

  it "groups completed sales by user, text name and unlinked" do
    expect(rows.map(&:to_h)).to eq([
      { key: "user:#{maria.id}", name: "maria", kind: :user, sales_count: 2, revenue: 30, share: 54.5, change: 50.0 },
      { key: "name:JOAO SILVA", name: "JOAO SILVA", kind: :name, sales_count: 2, revenue: 20, share: 36.4, change: 100.0 },
      { key: "none", name: "Não vinculado", kind: :none, sales_count: 1, revenue: 5, share: 9.1, change: nil }
    ])
  end

  it "keeps sales of a deleted user under their username as text" do
    pedro = member("pedro")
    sale(Date.new(2026, 8, 11), 1, seller: pedro)
    pedro.destroy!
    expect(rows.find { |row| row.key == "name:PEDRO" }).to have_attributes(name: "pedro", kind: :name)
  end

  it "keeps listing a seller who left the organization" do
    maria.memberships.destroy_all
    expect(rows.first).to have_attributes(name: "maria", kind: :user)
  end
end

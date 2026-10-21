require "rails_helper"

RSpec.describe Reports::SellerKey do
  let(:organization) { create(:organization) }
  let(:product) { create(:product, organization: organization) }

  it "builds keys for users, text names and unlinked sales" do
    expect(described_class.for(seller_id: 7, responsible_name: "x")).to eq("user:7")
    expect(described_class.for(seller_id: nil, responsible_name: " joão silva ")).to eq("name:JOAO SILVA")
    expect(described_class.for(seller_id: nil, responsible_name: " ")).to eq("none")
  end

  it "validates key format" do
    expect(%w[user:7 name:JOAO none].map { |key| described_class.valid?(key) }).to all(be(true))
    expect([ "user:abc", "x", "", nil ].map { |key| described_class.valid?(key) }).to all(be(false))
  end

  it "filters sales by text name across spellings, excluding linked sales" do
    linked_user = create(:user, username: "JOAO SILVA")
    create(:membership, user: linked_user, organization: organization, role: "manager")
    accented = create_report_sale(organization: organization, date: Date.new(2026, 8, 1), items: [ [ product, 1, 1 ] ], responsible_name: "João Silva")
    plain = create_report_sale(organization: organization, date: Date.new(2026, 8, 2), items: [ [ product, 1, 1 ] ], responsible_name: "JOAO SILVA")
    create_report_sale(organization: organization, date: Date.new(2026, 8, 3), items: [ [ product, 1, 1 ] ], seller: linked_user, responsible_name: "JOAO SILVA")
    unlinked = create_report_sale(organization: organization, date: Date.new(2026, 8, 4), items: [ [ product, 1, 1 ] ])

    by_name = organization.sales.merge(described_class.sales_condition("name:JOAO SILVA", organization: organization))
    by_none = organization.sales.merge(described_class.sales_condition("none", organization: organization))

    expect(by_name).to contain_exactly(accented, plain)
    expect(by_none).to contain_exactly(unlinked)
  end

  it "restricts every condition to the given organization", :aggregate_failures do
    plain = create_report_sale(organization: organization, date: Date.new(2026, 8, 1), items: [ [ product, 1, 1 ] ], responsible_name: "JOAO SILVA")
    unlinked = create_report_sale(organization: organization, date: Date.new(2026, 8, 2), items: [ [ product, 1, 1 ] ])
    other = create(:organization)
    other_product = create(:product, organization: other)
    other_seller = create(:user).tap { |user| create(:membership, user: user, organization: other, role: "manager") }
    create_report_sale(organization: other, date: Date.new(2026, 8, 1), items: [ [ other_product, 1, 1 ] ], responsible_name: "JOAO SILVA")
    create_report_sale(organization: other, date: Date.new(2026, 8, 2), items: [ [ other_product, 1, 1 ] ])
    create_report_sale(organization: other, date: Date.new(2026, 8, 3), items: [ [ other_product, 1, 1 ] ], seller: other_seller)

    expect(Sale.merge(described_class.sales_condition("name:JOAO SILVA", organization: organization))).to contain_exactly(plain)
    expect(Sale.merge(described_class.sales_condition("none", organization: organization))).to contain_exactly(unlinked)
    expect(Sale.merge(described_class.sales_condition("user:#{other_seller.id}", organization: organization))).to be_empty
  end
end

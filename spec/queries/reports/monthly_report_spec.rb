require "rails_helper"

RSpec.describe Reports::MonthlyReport do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }

  def report(month: nil, seller: nil)
    described_class.new(organization: organization, filters: Reports::Filters.new({ month: month, seller: seller }, organization: organization, today: today))
  end

  it "offers months from the first sale to the current month" do
    create_report_sale(organization: organization, date: Date.new(2026, 6, 15), status: "pending", items: [ [ create(:product, organization: organization), 1, 1 ] ])
    expect(report.month_options).to eq([ 10, 9, 8, 7, 6 ].map { |m| Date.new(2026, m, 1) })
    expect(report(month: "2026-03").month_options.last).to eq(Date.new(2026, 3, 1))
  end

  it "offers only the current month without sales" do
    expect(report.month_options).to eq([ Date.new(2026, 10, 1) ])
  end

  it "ignores a well-formed seller key that is not among the seller options" do
    foreign_user = create(:membership, organization: create(:organization)).user

    expect(report(seller: "user:#{foreign_user.id}").seller_key).to be_nil
  end

  it "keeps a seller key that is among the seller options" do
    member = create(:membership, organization: organization).user

    expect(report(seller: "user:#{member.id}").seller_key).to eq("user:#{member.id}")
  end
end

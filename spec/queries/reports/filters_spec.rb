require "rails_helper"

RSpec.describe Reports::Filters do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }
  let(:product) { create(:product, organization: organization) }

  def filters(params) = described_class.new(params, organization: organization, today: today)

  it "reads month, comparison, product and seller" do
    result = filters(ActionController::Parameters.new(month: "2026-08", comparison: "current", product_id: product.id.to_s, seller: "user:1").permit!)
    expect(result.period).to have_attributes(month: Date.new(2026, 8, 1), comparison: :current)
    expect(result.product).to eq(product)
    expect(result.seller_key).to eq("user:1")
  end

  it "falls back to defaults for invalid or foreign values" do
    [ "2026-13", "abc", "", "2027-01" ].each do |month|
      expect(filters(month: month).period.month).to eq(Date.new(2026, 10, 1))
    end
    expect(filters(product_id: create(:product).id).product).to be_nil
    expect(filters(seller: "garbage").seller_key).to be_nil
  end

  it "falls back to the current month for a year before 2000" do
    [ "0001-01", "1999-12" ].each do |month|
      expect(filters(month: month).period.month).to eq(Date.new(2026, 10, 1))
    end
    expect(filters(month: "2000-01").period.month).to eq(Date.new(2000, 1, 1))
  end
end

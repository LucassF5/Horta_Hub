require "rails_helper"

RSpec.describe Reports::Summary do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }
  let(:a) { create(:product, organization: organization) }
  let(:b) { create(:product, organization: organization) }

  def summary(month:, comparison: "previous", product: nil)
    period = Reports::Period.new(month: month, comparison: comparison, today: today)
    described_class.new(scope: Reports::Scope.new(organization: organization, product: product), period: period)
  end

  def sale(date, items, status: "completed") = create_report_sale(organization: organization, date: date, status: status, items: items)

  context "with a year of sales" do
    before do
      sale(Date.new(2026, 7, 5), [ [ a, 2, 10 ] ])
      sale(Date.new(2026, 7, 25), [ [ a, 1, 10 ] ])
      sale(Date.new(2026, 7, 3), [ [ b, 1, 5 ] ], status: "pending")
      sale(Date.new(2026, 8, 5), [ [ a, 3, 10 ] ])
      sale(Date.new(2026, 8, 18), [ [ b, 2, 5 ] ])
      sale(Date.new(2026, 8, 28), [ [ a, 1, 10 ] ])
      sale(Date.new(2026, 8, 3), [ [ b, 1, 5 ] ], status: "pending")
      sale(Date.new(2026, 8, 25), [ [ b, 2, 5 ] ], status: "pending")
      sale(Date.new(2026, 8, 10), [ [ a, 1, 10 ] ], status: "cancelled")
      sale(Date.new(2026, 9, 10), [ [ a, 2, 10 ] ])
      sale(Date.new(2026, 9, 25), [ [ b, 2, 5 ] ])
      sale(Date.new(2026, 10, 2), [ [ a, 2, 10 ] ])
      sale(Date.new(2026, 10, 19), [ [ b, 1, 5 ] ])
      sale(Date.new(2026, 10, 25), [ [ a, 1, 10 ] ])
    end

    it "shows August against July and against the same days of October" do
      result = summary(month: Date.new(2026, 8, 1))
      expect(result.revenue.to_h).to eq(value: 50, change: 66.7, current_change: 60.0)
      expect(result.sales_count.to_h).to eq(value: 3, change: 50.0, current_change: 0.0)
      expect(result.units.to_h).to eq(value: 6, change: 100.0, current_change: 66.7)
      expect(result.ticket.to_h).to eq(value: 16.67, change: 11.1, current_change: 60.0)
      expect(result.pending.to_h).to eq(count: 2, value: 15, share: 33.3, change: 100.0, current_change: nil)
      expect(result.cancelled.to_h).to eq(count: 1, value: 10, share: 16.7, change: nil, current_change: nil)
    end

    it "uses the same days when comparing with the current month" do
      result = summary(month: Date.new(2026, 8, 1), comparison: "current")
      expect(result.revenue.change).to eq(60.0)
      expect(result.revenue.current_change).to be_nil
    end

    it "shows the whole current month but compares only up to today" do
      result = summary(month: Date.new(2026, 10, 1))
      expect(result.revenue.value).to eq(35)
      expect(result.revenue.change).to eq(25.0)
    end

    it "applies the product filter to every metric" do
      result = summary(month: Date.new(2026, 8, 1), product: b)
      expect(result.revenue.to_h).to include(value: 10, change: nil)
      expect(result.sales_count.value).to eq(1)
      expect(result.units.value).to eq(2)
    end
  end

  it "matches the dashboard for the current month with decimal prices" do
    sale(Date.new(2026, 10, 5), [ [ a, 3, 4.10 ], [ b, 1, 0.35 ] ])
    sale(Date.new(2026, 10, 6), [ [ a, 1, 4.10 ] ], status: "pending")
    sale(Date.new(2026, 10, 7), [ [ b, 2, 0.35 ] ], status: "cancelled")
    result = summary(month: Date.new(2026, 10, 1))
    dashboard = Dashboard::OverviewQuery.new(organization: organization, today: today)

    expect(result.revenue.value).to eq(BigDecimal("12.65"))
    expect(result.revenue.value).to eq(dashboard.revenue)
    expect(result.sales_count.value + result.pending.count + result.cancelled.count).to eq(dashboard.sales_count)
  end

  it "returns zeros and no percentages without sales" do
    result = summary(month: Date.new(2026, 10, 1))
    expect(result.revenue.to_h).to eq(value: 0, change: nil, current_change: nil)
    expect(result.ticket.value).to be_nil
    expect(result.pending.share).to be_nil
  end
end

require "rails_helper"

RSpec.describe Reports::YearSeries do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }
  let(:a) { create(:product, organization: organization) }
  let(:b) { create(:product, organization: organization) }

  def points(month:, product: nil)
    period = Reports::Period.new(month: month, comparison: "previous", today: today)
    described_class.new(scope: Reports::Scope.new(organization: organization, product: product), period: period).points
  end

  before do
    [
      [ Date.new(2025, 12, 15), [ [ a, 1, 10 ] ], "completed" ],
      [ Date.new(2026, 1, 10), [ [ a, 2, 10 ] ], "completed" ],
      [ Date.new(2026, 1, 12), [ [ a, 10, 10 ] ], "pending" ],
      [ Date.new(2026, 3, 5), [ [ b, 3, 5 ] ], "completed" ],
      [ Date.new(2026, 9, 10), [ [ a, 2, 10 ] ], "completed" ],
      [ Date.new(2026, 9, 25), [ [ b, 2, 5 ] ], "completed" ],
      [ Date.new(2026, 10, 2), [ [ a, 2, 10 ], [ b, 1, 5 ] ], "completed" ],
      [ Date.new(2026, 10, 25), [ [ a, 1, 10 ] ], "completed" ]
    ].each { |date, items, status| create_report_sale(organization: organization, date: date, items: items, status: status) }
  end

  it "returns completed revenue, change and state for each month of the selected year" do
    result = points(month: Date.new(2026, 8, 1))
    expect(result.map(&:month)).to eq((1..12).map { |m| Date.new(2026, m, 1) })
    expect(result.map(&:revenue)).to eq([ 20, 0, 15, 0, 0, 0, 0, 0, 30, 35, nil, nil ])
    expect(result.map(&:change)).to eq([ 100.0, -100.0, nil, -100.0, nil, nil, nil, nil, nil, 25.0, nil, nil ])
    expect(result.map(&:state)).to eq([ :past ] * 9 + [ :current, :future, :future ])
  end

  it "applies the product filter" do
    result = points(month: Date.new(2026, 8, 1), product: b)
    expect(result[8].revenue).to eq(10)
    expect(result[9].revenue).to eq(5)
  end

  it "marks every month of a past year as past" do
    result = points(month: Date.new(2025, 3, 1))
    expect(result.map(&:state).uniq).to eq([ :past ])
    expect(result.last.revenue).to eq(10)
  end
end

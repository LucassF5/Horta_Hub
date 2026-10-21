require "rails_helper"

RSpec.describe Reports::Period do
  let(:today) { Date.new(2026, 10, 20) }
  def d(month, day) = Date.new(2026, month, day)

  it "compares a past month with the previous one in full and with the current month by the same days" do
    period = described_class.new(month: d(8, 15), comparison: "previous", today: today)
    expect(period.month).to eq(d(8, 1))
    expect(period.base_month).to eq(d(7, 1))
    expect(period.range).to eq(d(8, 1)..d(8, 31))
    expect(period.base_windows).to eq([ d(8, 1)..d(8, 31), d(7, 1)..d(7, 31) ])
    expect(period.current_windows).to eq([ d(8, 1)..d(8, 20), d(10, 1)..d(10, 20) ])
  end

  it "uses the same days when the base is the current month" do
    period = described_class.new(month: d(8, 1), comparison: "current", today: today)
    expect(period.comparison).to eq(:current)
    expect(period.base_windows).to eq([ d(8, 1)..d(8, 20), d(10, 1)..d(10, 20) ])
    expect(period.current_windows).to be_nil
  end

  it "compares the current month with the same days of the previous month" do
    period = described_class.new(month: d(10, 1), comparison: "previous", today: today)
    expect(period.base_windows).to eq([ d(10, 1)..d(10, 20), d(9, 1)..d(9, 20) ])
    expect(period.current_windows).to be_nil
  end

  it "treats 'current' as previous when the current month is selected" do
    period = described_class.new(month: d(10, 1), comparison: "current", today: today)
    expect(period.comparison).to eq(:previous)
    expect(period.base_month).to eq(d(9, 1))
  end

  it "clamps a future month to the current month" do
    expect(described_class.new(month: Date.new(2027, 1, 1), comparison: "previous", today: today).month).to eq(d(10, 1))
  end

  it "limits a shorter month to its last day on the 31st" do
    period = described_class.new(month: Date.new(2027, 3, 1), comparison: "previous", today: Date.new(2027, 3, 31))
    expect(period.base_windows).to eq([ Date.new(2027, 3, 1)..Date.new(2027, 3, 31), Date.new(2027, 2, 1)..Date.new(2027, 2, 28) ])
  end

  it "compares January with December of the previous year" do
    period = described_class.new(month: d(1, 1), comparison: "previous", today: today)
    expect(period.base_windows).to eq([ d(1, 1)..d(1, 31), Date.new(2025, 12, 1)..Date.new(2025, 12, 31) ])
  end

  it "lists the twelve months of the selected year" do
    expect(described_class.new(month: d(8, 1), comparison: "previous", today: today).year_months).to eq((1..12).map { |m| d(m, 1) })
  end
end

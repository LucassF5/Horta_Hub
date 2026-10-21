require "rails_helper"

RSpec.describe Views::Reports::Formatting do
  subject(:format) { Class.new { include Views::Reports::Formatting }.new }

  it "formats money and percentages in pt-BR" do
    expect(format.currency(BigDecimal("1234.5"))).to eq("R$ 1.234,50")
    expect(format.percent(BigDecimal("63.2"))).to eq("63,2%")
    expect(format.percent(nil)).to eq("—")
  end

  it "formats changes with arrows and tones" do
    expect(format.change_text(BigDecimal("66.7"))).to eq("▲ 66,7%")
    expect(format.change_text(BigDecimal("-100"))).to eq("▼ 100,0%")
    expect(format.change_text(0)).to eq("0,0%")
    expect(format.change_text(nil)).to eq("—")
    expect(format.change_tone(BigDecimal("66.7"))).to eq(:positive)
    expect(format.change_tone(BigDecimal("66.7"), inverted: true)).to eq(:negative)
    expect(format.change_tone(nil)).to eq(:neutral)
  end

  it "labels whole and partial months" do
    expect(format.period_label(Date.new(2026, 7, 1)..Date.new(2026, 7, 31))).to eq("jul/2026")
    expect(format.period_label(Date.new(2026, 10, 1)..Date.new(2026, 10, 20))).to eq("1 a 20 de out/2026")
  end
end

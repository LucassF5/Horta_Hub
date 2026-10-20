require "rails_helper"

RSpec.describe PersonName do
  it "ignores case, accents and repeated spaces" do
    expect(described_class.normalize("  João   da Silva ")).to eq("JOAO DA SILVA")
  end

  it "returns an empty string for nil" do
    expect(described_class.normalize(nil)).to eq("")
  end
end

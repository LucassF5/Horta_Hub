require "rails_helper"

RSpec.describe Percentage do
  it { expect(described_class.change(150, 100)).to eq(50.0) }
  it { expect(described_class.change(1, 3)).to eq(-66.7) }
  it { expect(described_class.change(0, 100)).to eq(-100.0) }
  it { expect(described_class.change(10, 0)).to be_nil }
  it { expect(described_class.change(10, nil)).to be_nil }
  it { expect(described_class.share(1, 3)).to eq(33.3) }
  it { expect(described_class.share(5, 0)).to be_nil }
end

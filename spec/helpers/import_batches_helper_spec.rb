require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the ImportBatchesHelper. For example:
#
# describe ImportBatchesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ImportBatchesHelper, type: :helper do
  it "is available" do
    expect(helper).to be_present
  end
end

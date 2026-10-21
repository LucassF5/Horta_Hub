require "rails_helper"

RSpec.describe ReportPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:membership) { create(:membership, user: user, organization: organization, role: role) }
  let(:context) { { user: user, membership: membership, organization: organization } }
  let(:record) { :report }

  describe_rule :show? do
    %w[owner admin manager].each do |role_name|
      context "when membership is #{role_name}" do
        let(:role) { role_name }

        succeed
      end
    end

    context "when membership is viewer" do
      let(:role) { "viewer" }

      failed
    end
  end
end

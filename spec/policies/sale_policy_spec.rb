require "rails_helper"

RSpec.describe SalePolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:membership) { create(:membership, user: user, organization: organization, role: role) }
  let(:role) { "owner" }
  let(:context) { { user: user, membership: membership, organization: organization } }

  describe_rule :index? do
    let(:record) { Sale }

    %w[owner admin manager viewer].each do |role_name|
      context "when membership is #{role_name}" do
        let(:role) { role_name }

        succeed
      end
    end
  end

  describe_rule :show? do
    let(:role) { "viewer" }

    context "when sale belongs to the membership organization" do
      let(:record) { create(:sale, organization: organization) }

      succeed
    end

    context "when sale belongs to another organization" do
      let(:record) { create(:sale) }

      failed
    end
  end

  describe_rule :create? do
    let(:record) { organization.sales.build }

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

  describe_rule :update? do
    let(:record) { create(:sale, organization: organization) }

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

    context "when sale belongs to another organization" do
      let(:record) { create(:sale) }

      failed
    end
  end

  describe_rule :destroy? do
    let(:record) { create(:sale, organization: organization) }

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

    context "when sale belongs to another organization" do
      let(:record) { create(:sale) }

      failed
    end
  end
end

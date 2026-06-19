require "rails_helper"

RSpec.describe ClientPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:membership) { create(:membership, user: user, organization: organization, role: role) }
  let(:role) { "owner" }
  let(:context) { { user: user, membership: membership, organization: organization } }

  describe_rule :index? do
    let(:record) { Client }

    %w[owner admin manager viewer].each do |role_name|
      context "when membership is #{role_name}" do
        let(:role) { role_name }

        succeed
      end
    end
  end

  describe_rule :show? do
    let(:role) { "viewer" }

    context "when client belongs to the membership organization" do
      let(:record) { create(:client, organization: organization) }

      succeed
    end

    context "when client belongs to another organization" do
      let(:record) { create(:client) }

      failed
    end
  end

  describe_rule :create? do
    let(:record) { organization.clients.build }

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
    let(:record) { create(:client, organization: organization) }

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

    context "when client belongs to another organization" do
      let(:record) { create(:client) }

      failed
    end
  end

  describe_rule :destroy? do
    let(:record) { create(:client, organization: organization) }

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

    context "when client belongs to another organization" do
      let(:record) { create(:client) }

      failed
    end

    context "when client has sales" do
      before { create(:sale, organization: organization, client: record) }

      failed
    end
  end
end

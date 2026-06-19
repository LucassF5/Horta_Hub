require "rails_helper"

RSpec.describe ProductPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:membership) { create(:membership, user: user, organization: organization, role: role) }
  let(:role) { "owner" }
  let(:context) { { user: user, membership: membership, organization: organization } }

  describe_rule :index? do
    let(:record) { Product }

    %w[owner admin manager viewer].each do |role_name|
      context "when membership is #{role_name}" do
        let(:role) { role_name }

        succeed
      end
    end
  end

  describe_rule :show? do
    let(:role) { "viewer" }

    context "when product belongs to the membership organization" do
      let(:record) { create(:product, organization: organization) }

      succeed
    end

    context "when product belongs to another organization" do
      let(:record) { create(:product) }

      failed
    end
  end

  describe_rule :create? do
    let(:record) { organization.products.build }

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
    let(:record) { create(:product, organization: organization) }

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

    context "when product belongs to another organization" do
      let(:record) { create(:product) }

      failed
    end
  end

  describe_rule :destroy? do
    let(:record) { create(:product, organization: organization) }

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

    context "when product belongs to another organization" do
      let(:record) { create(:product) }

      failed
    end

    context "when product has sale items" do
      before do
        sale = create(:sale, organization: organization)
        create(:sale_item, sale: sale, product: record)
      end

      failed
    end
  end
end

require "rails_helper"

RSpec.describe MembershipPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:membership) { create(:membership, user: user, organization: organization, role: role) }
  let(:role) { "owner" }
  let(:context) { { user: user, membership: membership, organization: organization } }

  def member_with_role(role, organization: self.organization)
    create(:membership, organization: organization, role: role)
  end

  def changing_role(from:, to:)
    member_with_role(from).tap { |target| target.role = to }
  end

  describe_rule :index? do
    let(:record) { Membership }

    %w[owner admin].each do |role_name|
      context "when membership is #{role_name}" do
        let(:role) { role_name }

        succeed
      end
    end

    %w[manager viewer].each do |role_name|
      context "when membership is #{role_name}" do
        let(:role) { role_name }

        failed
      end
    end
  end

  describe_rule :create? do
    context "when owner creates an owner" do
      let(:record) { organization.memberships.build(role: "owner") }

      succeed
    end

    %w[admin manager viewer].each do |new_role|
      context "when admin creates a #{new_role}" do
        let(:role) { "admin" }
        let(:record) { organization.memberships.build(role: new_role) }

        succeed
      end
    end

    context "when admin creates an owner" do
      let(:role) { "admin" }
      let(:record) { organization.memberships.build(role: "owner") }

      failed
    end

    context "when admin creates an invalid role" do
      let(:role) { "admin" }
      let(:record) { organization.memberships.build(role: "superuser") }

      failed
    end

    context "when manager creates a viewer" do
      let(:role) { "manager" }
      let(:record) { organization.memberships.build(role: "viewer") }

      failed
    end

    context "when record belongs to another organization" do
      let(:record) { create(:organization).memberships.build(role: "viewer") }

      failed
    end
  end

  describe_rule :update? do
    context "when owner promotes a viewer to admin" do
      let(:record) { changing_role(from: "viewer", to: "admin") }

      succeed
    end

    context "when admin demotes a manager to viewer" do
      let(:role) { "admin" }
      let(:record) { changing_role(from: "manager", to: "viewer") }

      succeed
    end

    context "when admin demotes another admin to viewer" do
      let(:role) { "admin" }
      let(:record) { changing_role(from: "admin", to: "viewer") }

      succeed
    end

    context "when admin promotes a viewer to owner" do
      let(:role) { "admin" }
      let(:record) { changing_role(from: "viewer", to: "owner") }

      failed
    end

    context "when admin edits an owner" do
      let(:role) { "admin" }
      let(:record) { changing_role(from: "owner", to: "viewer") }

      failed
    end

    context "when owner edits its own membership" do
      let(:record) { membership }

      failed
    end

    context "when record belongs to another organization" do
      let(:record) { member_with_role("viewer", organization: create(:organization)) }

      failed
    end
  end

  describe_rule :destroy? do
    context "when owner removes an admin" do
      let(:record) { member_with_role("admin") }

      succeed
    end

    context "when admin removes an owner" do
      let(:role) { "admin" }
      let(:record) { member_with_role("owner") }

      failed
    end

    context "when owner removes itself" do
      let(:record) { membership }

      failed
    end

    context "when manager removes a viewer" do
      let(:role) { "manager" }
      let(:record) { member_with_role("viewer") }

      failed
    end
  end

  describe_rule :reset_password? do
    context "when owner resets a viewer that belongs only to this organization" do
      let(:record) { member_with_role("viewer") }

      succeed
    end

    context "when the viewer also belongs to another organization" do
      let(:record) { member_with_role("viewer") }

      before { create(:membership, user: record.user, role: "viewer") }

      failed
    end

    context "when admin resets an owner" do
      let(:role) { "admin" }
      let(:record) { member_with_role("owner") }

      failed
    end

    context "when owner resets itself" do
      let(:record) { membership }

      failed
    end
  end
end

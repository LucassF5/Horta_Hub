require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:role) }

    it 'prevents duplicate membership in the same organization' do
      membership = create(:membership)
      duplicate = build(:membership, user: membership.user, organization: membership.organization)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'allows the same user in different organizations' do
      user = create(:user)
      create(:membership, user: user)

      expect(build(:membership, user: user, organization: create(:organization))).to be_valid
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).backed_by_column_of_type(:string).with_values(owner: "owner", admin: "admin", manager: "manager", viewer: "viewer") }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:membership)).to be_valid
    end
  end

  describe 'role hierarchy' do
    it "orders roles by rank" do
      owner = build(:membership, role: "owner")
      admin = build(:membership, :admin)
      manager = build(:membership, :manager)
      viewer = build(:membership, :viewer)

      expect(owner.rank).to be > admin.rank
      expect(admin.rank).to be > manager.rank
      expect(manager.rank).to be > viewer.rank
    end

    it "lets owner assign every role" do
      expect(build(:membership).assignable_roles).to eq(%w[owner admin manager viewer])
    end

    it "lets admin assign admin, manager and viewer" do
      expect(build(:membership, :admin).assignable_roles).to eq(%w[admin manager viewer])
    end

    it "lets manager and viewer assign nothing" do
      expect(build(:membership, :manager).assignable_roles).to eq([])
      expect(build(:membership, :viewer).assignable_roles).to eq([])
    end

    it "lets only owner and admin manage members" do
      expect(build(:membership).manages_members?).to be true
      expect(build(:membership, :admin).manages_members?).to be true
      expect(build(:membership, :manager).manages_members?).to be false
      expect(build(:membership, :viewer).manages_members?).to be false
    end

    it "acts only on assignable roles" do
      admin = build(:membership, :admin)

      expect(admin.can_act_on_role?(:manager)).to be true
      expect(admin.can_act_on_role?("owner")).to be false
      expect(build(:membership, :manager).can_act_on_role?("viewer")).to be false
    end

    it "rejects an unknown role without raising" do
      membership = build(:membership, role: "superuser")

      expect(membership).not_to be_valid
      expect(membership.errors[:role]).to be_present
    end
  end

  describe 'role labels' do
    it "labels roles in Portuguese" do
      expect(Membership.role_label("owner")).to eq("Dono")
      expect(Membership.role_label("admin")).to eq("Administrador")
      expect(Membership.role_label("manager")).to eq("Gerente")
      expect(Membership.role_label("viewer")).to eq("Visualizador")
    end

    it "labels its own role" do
      expect(build(:membership, :manager).role_label).to eq("Gerente")
    end
  end

  describe "last owner guard" do
    let(:organization) { create(:organization) }
    let!(:owner) { create(:membership, organization: organization) }

    context "with a single owner" do
      it "prevents demoting the owner" do
        expect(owner.update(role: "admin")).to be false
        expect(owner.errors[:role]).to include("a organização precisa de pelo menos um dono")
        expect(owner.reload).to be_owner
      end

      it "prevents destroying the owner" do
        expect(owner.destroy).to be false
        expect(owner.errors[:base]).to include("a organização precisa de pelo menos um dono")
        expect(Membership.exists?(owner.id)).to be true
      end

      it "allows destroying the organization with its memberships" do
        organization.destroy

        expect(Organization.exists?(organization.id)).to be false
        expect(Membership.exists?(owner.id)).to be false
      end
    end

    context "with two owners" do
      let!(:other_owner) { create(:membership, organization: organization) }

      it "allows demoting one of them" do
        expect(owner.update(role: "admin")).to be true
        expect(owner.reload).to be_admin
      end

      it "allows destroying one of them" do
        expect(owner.destroy).to be_truthy
        expect(Membership.exists?(owner.id)).to be false
      end
    end

    it "ignores owners of other organizations" do
      create(:membership)

      expect(owner.update(role: "admin")).to be false
    end
  end

  describe "#sole_organization?" do
    it "detects sole organization" do
      membership = create(:membership)

      expect(membership.sole_organization?).to be true

      create(:membership, :viewer, user: membership.user)

      expect(membership.sole_organization?).to be false
    end
  end
end

# == Schema Information
#
# Table name: memberships
#
#  id              :integer          not null, primary key
#  role            :string           default("viewer"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_memberships_on_organization_id              (organization_id)
#  index_memberships_on_organization_id_and_user_id  (organization_id,user_id) UNIQUE
#  index_memberships_on_user_id                      (user_id)
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#  user_id          (user_id => users.id)
#

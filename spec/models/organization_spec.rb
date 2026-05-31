require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'associations' do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:users).through(:memberships) }
    it { should have_many(:products).dependent(:restrict_with_error) }
    it { should have_many(:clients).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    subject { build(:organization) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }
    it { should validate_uniqueness_of(:slug) }
    it { should validate_presence_of(:status) }

    it 'validates slug format' do
      org = build(:organization, slug: "INVALID SLUG!")
      expect(org).not_to be_valid
      expect(org.errors[:slug]).to be_present
    end

    it 'accepts valid slug' do
      org = build(:organization, slug: "valid-slug-123")
      expect(org).to be_valid
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).backed_by_column_of_type(:string).with_values(active: "active", inactive: "inactive") }
  end

  describe 'callbacks' do
    it 'generates slug from name on create' do
      org = create(:organization, name: "My Organization", slug: nil)
      expect(org.slug).to eq("my-organization")
    end

    it 'does not overwrite existing slug' do
      org = create(:organization, name: "My Org", slug: "custom-slug")
      expect(org.slug).to eq("custom-slug")
    end
  end

  describe '#membership_for' do
    let(:organization) { create(:organization) }
    let(:user) { create(:user) }
    let!(:membership) { create(:membership, user: user, organization: organization) }

    it 'returns membership for user' do
      expect(organization.membership_for(user)).to eq(membership)
    end

    it 'returns nil for unknown user' do
      other_user = create(:user)
      expect(organization.membership_for(other_user)).to be_nil
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:organization)).to be_valid
    end
  end
end

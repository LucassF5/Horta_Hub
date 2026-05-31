require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:membership) }

    it { should validate_presence_of(:role) }
    it { should validate_uniqueness_of(:user_id).with_message("already assigned to an organization") }
  end

  describe 'enums' do
    it { should define_enum_for(:role).backed_by_column_of_type(:string).with_values(owner: "owner", admin: "admin", manager: "manager", viewer: "viewer") }
  end

  describe '#can_manage?' do
    it 'returns true for owner' do
      expect(build(:membership, :admin).tap { |m| m.role = "owner" }.can_manage?).to be true
    end

    it 'returns true for admin' do
      expect(build(:membership, :admin).can_manage?).to be true
    end

    it 'returns true for manager' do
      expect(build(:membership, :manager).can_manage?).to be true
    end

    it 'returns false for viewer' do
      expect(build(:membership, :viewer).can_manage?).to be false
    end
  end

  describe '#read_only?' do
    it 'returns true for viewer' do
      expect(build(:membership, :viewer).read_only?).to be true
    end

    it 'returns false for owner' do
      expect(build(:membership).read_only?).to be false
    end

    it 'returns false for admin' do
      expect(build(:membership, :admin).read_only?).to be false
    end

    it 'returns false for manager' do
      expect(build(:membership, :manager).read_only?).to be false
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:membership)).to be_valid
    end
  end
end

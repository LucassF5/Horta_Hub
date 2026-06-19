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

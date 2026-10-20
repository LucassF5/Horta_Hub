require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:organizations).through(:memberships) }
    it { should have_many(:sold_sales).class_name("Sale").with_foreign_key(:seller_id).inverse_of(:seller) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:username) }
    it { should validate_length_of(:username).is_at_least(3).is_at_most(30) }
    it { should validate_presence_of(:email_address) }
    it { should validate_uniqueness_of(:email_address).case_insensitive }
    it { should have_secure_password }
  end

  describe 'normalizations' do
    it 'normalizes email_address to stripped lowercase' do
      user = create(:user, email_address: "  Test@Example.COM  ")
      expect(user.email_address).to eq("test@example.com")
    end
  end

  describe '#membership_for' do
    let(:organization) { create(:organization) }
    let(:other_organization) { create(:organization) }
    let(:user) { create(:user) }
    let!(:membership) { create(:membership, user: user, organization: organization) }
    let!(:other_membership) { create(:membership, user: user, organization: other_organization, role: "viewer") }

    it 'returns membership for matching organization' do
      expect(user.membership_for(organization)).to eq(membership)
    end

    it 'returns the matching membership when user belongs to multiple organizations' do
      expect(user.membership_for(other_organization)).to eq(other_membership)
    end

    it 'returns nil for non-matching organization' do
      other_org = create(:organization)
      expect(user.membership_for(other_org)).to be_nil
    end

    it 'returns nil for nil organization' do
      expect(user.membership_for(nil)).to be_nil
    end
  end

  describe '.generate_password' do
    it "generates 8-character alphanumeric passwords" do
      expect(User.generate_password).to match(/\A[a-zA-Z0-9]{8}\z/)
    end
  end

  describe '#reset_password!' do
    it "resets the password and ends sessions" do
      user = create(:user)
      create_list(:session, 2, user: user)

      password = user.reset_password!

      expect(user.reload.authenticate(password)).to be_truthy
      expect(user.authenticate("password123")).to be false
      expect(user.sessions.count).to eq(0)
    end
  end

  describe '#member_of_active_organization?' do
    it "knows whether it belongs to an active organization" do
      user = create(:user)

      expect(user.member_of_active_organization?).to be false

      create(:membership, user: user, organization: create(:organization, status: "inactive"))

      expect(user.member_of_active_organization?).to be false

      create(:membership, user: user, organization: create(:organization))

      expect(user.member_of_active_organization?).to be true
    end
  end

  describe "account deletion" do
    it "unlinks the user's sales in every organization and keeps the username as text" do
      user = create(:user, username: "maria")
      sales = create_list(:organization, 2).map do |organization|
        create(:membership, user: user, organization: organization, role: "manager")
        create(:sale, organization: organization, seller: user)
      end

      user.destroy!

      sales.each { |sale| expect(sale.reload).to have_attributes(seller_id: nil, responsible_name: "maria") }
    end

    it "keeps the seller link when the account cannot be deleted" do
      user = create(:user)
      organization = create(:organization)
      create(:membership, user: user, organization: organization, role: "owner")
      sale = create(:sale, organization: organization, seller: user)

      expect(user.destroy).to be(false)
      expect(sale.reload.seller_id).to eq(user.id)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end

    it 'creates user with organization' do
      user = create(:user, :with_organization)
      expect(user.organizations).to be_present
    end
  end
end

# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email_address   :string           not null
#  password_digest :string           not null
#  username        :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#

require 'rails_helper'

RSpec.describe Client, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
  end

  describe 'validations' do
    subject { build(:client) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:client_type) }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(30) }
  end

  describe 'enums' do
    it { should define_enum_for(:client_type).backed_by_column_of_type(:string).with_values(pessoa_fisica: "Pessoa Física", pessoa_juridica: "Pessoa Jurídica") }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:client)).to be_valid
    end

    it 'creates pessoa_juridica clients' do
      client = build(:client, :pessoa_juridica)
      expect(client.client_type).to eq("pessoa_juridica")
    end

    it 'creates clients without phone' do
      client = build(:client, :without_phone)
      expect(client.phone).to be_nil
      expect(client).to be_valid
    end
  end

  describe 'name validation' do
    it 'is invalid with name too short' do
      client = build(:client, name: "ab")
      expect(client).not_to be_valid
    end

    it 'is invalid with name too long' do
      client = build(:client, name: "a" * 31)
      expect(client).not_to be_valid
    end
  end
end

# == Schema Information
#
# Table name: clients
#
#  id              :integer          not null, primary key
#  client_type     :string           not null
#  name            :string(65)       not null
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#

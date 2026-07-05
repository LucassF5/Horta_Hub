require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
  end

  describe 'validations' do
    subject { build(:product) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:price) }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(50) }
    it { should validate_numericality_of(:price).is_greater_than(0) }

    context 'uniqueness validation' do
      let(:organization) { create(:organization) }
      let!(:existing_product) { create(:product, name: "Test Product", organization: organization) }

      it 'validates uniqueness of name scoped to organization' do
        duplicate_product = build(:product, name: "Test Product", organization: organization)
        expect(duplicate_product).not_to be_valid
        expect(duplicate_product.errors[:name]).to be_present
      end

      it 'allows same name in different organizations' do
        other_organization = create(:organization)
        other_product = build(:product, name: "Test Product", organization: other_organization)
        expect(other_product).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe '#format_name' do
      it 'formats name to titlecase before save' do
        product = create(:product, name: "test product name")
        expect(product.reload.name).to eq("Test Product Name")
      end

      it 'handles multiple spaces correctly' do
        product = create(:product, name: "test  product   name")
        expect(product.reload.name).to eq("Test  Product   Name")
      end

      it 'handles already formatted names' do
        product = create(:product, name: "Test Product Name")
        expect(product.reload.name).to eq("Test Product Name")
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      product = build(:product)
      expect(product).to be_valid
    end

    it 'creates expensive products' do
      product = create(:product, :expensive)
      expect(product.price).to be >= 100
    end

    it 'creates cheap products' do
      product = create(:product, :cheap)
      expect(product.price).to be <= 10
    end
  end

  describe 'price validation' do
    it 'is invalid with negative price' do
      product = build(:product, price: -10)
      expect(product).not_to be_valid
      expect(product.errors[:price]).to be_present
    end

    it 'is invalid with zero price' do
      product = build(:product, price: 0)
      expect(product).not_to be_valid
      expect(product.errors[:price]).to be_present
    end

    it 'is valid with decimal price' do
      product = build(:product, price: 10.99)
      expect(product).to be_valid
    end
  end

  describe 'name validation' do
    it 'is invalid with name too short' do
      product = build(:product, name: "ab")
      expect(product).not_to be_valid
      expect(product.errors[:name]).to be_present
    end

    it 'is invalid with name too long' do
      product = build(:product, name: "a" * 51)
      expect(product).not_to be_valid
      expect(product.errors[:name]).to be_present
    end

    it 'is valid with name at minimum length' do
      product = build(:product, name: "abc")
      expect(product).to be_valid
    end

    it 'is valid with name at maximum length' do
      product = build(:product, name: "a" * 50)
      expect(product).to be_valid
    end
  end
end

# == Schema Information
#
# Table name: products
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  price           :decimal(10, 2)   not null
#  slug            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_products_on_organization_id_and_slug  (organization_id,slug) UNIQUE
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#

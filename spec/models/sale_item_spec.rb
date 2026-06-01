require 'rails_helper'

RSpec.describe SaleItem, type: :model do
  describe 'associations' do
    it { should belong_to(:sale) }
    it { should belong_to(:product) }
  end

  describe 'validations' do
    subject { build(:sale_item) }

    it { should validate_presence_of(:quantity) }
    it { should validate_presence_of(:unit_price) }
    it { should validate_numericality_of(:quantity).is_greater_than(0).only_integer }
    it { should validate_numericality_of(:unit_price).is_greater_than(0) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:sale_item)).to be_valid
    end
  end
end

# == Schema Information
#
# Table name: sale_items
#
#  id         :integer          not null, primary key
#  quantity   :integer          default(1), not null
#  unit_price :decimal(10, 2)   not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :integer          not null
#  sale_id    :integer          not null
#
# Indexes
#
#  index_sale_items_on_product_id  (product_id)
#  index_sale_items_on_sale_id     (sale_id)
#
# Foreign Keys
#
#  product_id  (product_id => products.id)
#  sale_id     (sale_id => sales.id)
#

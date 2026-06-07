require 'rails_helper'

RSpec.describe Sale, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:client) }
    it { should have_many(:sale_items).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:sale) }

    it { should validate_presence_of(:sale_date) }
    it { should validate_presence_of(:status) }
    it { should validate_numericality_of(:total).is_greater_than_or_equal_to(0) }

    it 'is invalid when the client belongs to another organization' do
      sale = build(:sale, organization: create(:organization), client: create(:client, organization: create(:organization)))

      expect(sale).not_to be_valid
      expect(sale.errors[:client]).to include('deve pertencer à mesma organização da venda')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).backed_by_column_of_type(:string).with_values(pending: "pending", completed: "completed", cancelled: "cancelled") }
  end

  describe 'callbacks' do
    describe '#calculate_total' do
      it 'calculates total from sale items before save' do
        sale = create(:sale)
        create(:sale_item, sale: sale, quantity: 2, unit_price: 10.0)
        create(:sale_item, sale: sale, quantity: 3, unit_price: 5.0)
        sale.sale_items.reload
        sale.save!
        sale.reload
        expect(sale.total).to eq(35.0)
      end

      it 'sets total to 0 when no items' do
        sale = create(:sale)
        sale.save!
        sale.reload
        expect(sale.total).to eq(0)
      end
    end
  end

  describe 'scopes' do
    describe '.recent' do
      it 'orders by sale_date descending' do
        organization = create(:organization)
        client = create(:client, organization: organization)
        old_sale = create(:sale, organization: organization, client: client, sale_date: 1.week.ago)
        new_sale = create(:sale, organization: organization, client: client, sale_date: Date.current)

        expect(Sale.recent).to eq([ new_sale, old_sale ])
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:sale)).to be_valid
    end

    it 'creates completed sales' do
      sale = build(:sale, :completed)
      expect(sale.status).to eq("completed")
    end

    it 'creates cancelled sales' do
      sale = build(:sale, :cancelled)
      expect(sale.status).to eq("cancelled")
    end
  end
end

# == Schema Information
#
# Table name: sales
#
#  id              :integer          not null, primary key
#  notes           :text
#  sale_date       :date             not null
#  status          :string           default("pending"), not null
#  total           :decimal(10, 2)   default(0.0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  client_id       :integer          not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_sales_on_client_id                      (client_id)
#  index_sales_on_organization_id                (organization_id)
#  index_sales_on_organization_id_and_sale_date  (organization_id,sale_date)
#
# Foreign Keys
#
#  client_id        (client_id => clients.id)
#  organization_id  (organization_id => organizations.id)
#

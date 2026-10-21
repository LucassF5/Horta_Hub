require 'rails_helper'

RSpec.describe Sale, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:client) }
    it { should belong_to(:seller).class_name("User").optional }
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

    it 'is invalid without sale items' do
      sale = build(:sale)
      sale.sale_items = []

      expect(sale).not_to be_valid
      expect(sale.errors[:base]).to include('A venda deve ter ao menos um item.')
    end

    it 'is invalid when all sale items are marked for destruction' do
      sale = create(:sale)
      sale.sale_items.each(&:mark_for_destruction)

      expect(sale).not_to be_valid
      expect(sale.errors[:base]).to include('A venda deve ter ao menos um item.')
    end

    it 'is valid when at least one sale item is kept' do
      sale = create(:sale)
      create(:sale_item, sale: sale)
      sale.sale_items.reload.first.mark_for_destruction

      expect(sale).to be_valid
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).backed_by_column_of_type(:string).with_values(pending: "pending", completed: "completed", cancelled: "cancelled") }
  end

  describe 'callbacks' do
    describe '#calculate_total' do
      it 'calculates total from sale items before save' do
        sale = build(:sale)
        sale.sale_items = [
          build(:sale_item, sale: sale, quantity: 2, unit_price: 10.0, custom_price: true),
          build(:sale_item, sale: sale, quantity: 3, unit_price: 5.0, custom_price: true)
        ]
        sale.save!
        sale.reload
        expect(sale.total).to eq(35.0)
      end

      it 'ignores sale items marked for destruction' do
        sale = build(:sale)
        sale.sale_items = [
          build(:sale_item, sale: sale, quantity: 2, unit_price: 10.0, custom_price: true),
          build(:sale_item, sale: sale, quantity: 3, unit_price: 5.0, custom_price: true)
        ]
        sale.save!

        sale.sale_items.last.mark_for_destruction
        sale.save!
        sale.reload
        expect(sale.total).to eq(20.0)
      end
    end
  end

  describe 'scopes' do
    describe '.recent' do
      it 'orders by sale_date descending' do
        organization = create(:organization)
        client = create(:client, organization: organization)
        old_sale = create(:sale, organization: organization, client: client, sale_date: Date.current - 1.week)
        new_sale = create(:sale, organization: organization, client: client, sale_date: Date.current)

        expect(Sale.where(id: [ old_sale.id, new_sale.id ]).recent).to eq([ new_sale, old_sale ])
      end
    end
  end

  describe "seller" do
    let(:organization) { create(:organization) }
    let(:seller) { create(:user, username: "maria") }

    it "accepts a member of the sale organization" do
      create(:membership, user: seller, organization: organization, role: "manager")
      expect(build(:sale, organization: organization, seller: seller)).to be_valid
    end

    it "rejects a user outside the sale organization" do
      sale = build(:sale, organization: organization, seller: seller)
      expect(sale).not_to be_valid
      expect(sale.errors[:seller]).to include("deve pertencer à mesma organização da venda")
    end

    it "keeps an old sale editable after the seller leaves the organization" do
      membership = create(:membership, user: seller, organization: organization, role: "manager")
      sale = create(:sale, organization: organization, seller: seller)
      membership.destroy!
      expect(sale.reload.update(notes: "Atualizada")).to be(true)
    end
  end

  describe "#seller_display_name" do
    it("uses the seller username") { expect(build(:sale, seller: build(:user, username: "maria")).seller_display_name).to eq("maria") }
    it("falls back to the stored name") { expect(build(:sale, responsible_name: "JOAO SILVA").seller_display_name).to eq("JOAO SILVA") }
    it("shows Não vinculado without seller or name") { expect(build(:sale, responsible_name: " ").seller_display_name).to eq("Não vinculado") }
  end

  describe ".link_unlinked_sellers" do
    it "links unlinked sales whose name matches one member of the sale organization" do
      organization = create(:organization)
      maria = create(:user, username: "maria")
      create(:membership, user: maria, organization: organization, role: "manager")
      matching = create(:sale, organization: organization, responsible_name: "MARIA")
      unmatched = create(:sale, organization: organization, responsible_name: "PEDRO")
      other_organization_sale = create(:sale, responsible_name: "MARIA")

      expect(Sale.link_unlinked_sellers).to eq(1)
      expect(matching.reload.seller).to eq(maria)
      expect(unmatched.reload.seller).to be_nil
      expect(other_organization_sale.reload.seller).to be_nil
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:sale)).to be_valid
    end

    it 'allows a responsible name' do
      sale = build(:sale, responsible_name: "Lucas")

      expect(sale).to be_valid
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
#  id               :integer          not null, primary key
#  notes            :text
#  responsible_name :string
#  sale_date        :date             not null
#  status           :string           default("pending"), not null
#  total            :decimal(10, 2)   default(0.0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  client_id        :integer          not null
#  organization_id  :integer          not null
#  seller_id        :integer
#
# Indexes
#
#  index_sales_on_client_id                      (client_id)
#  index_sales_on_organization_id                (organization_id)
#  index_sales_on_organization_id_and_sale_date  (organization_id,sale_date)
#  index_sales_on_seller_id                      (seller_id)
#
# Foreign Keys
#
#  client_id        (client_id => clients.id)
#  organization_id  (organization_id => organizations.id)
#  seller_id        (seller_id => users.id)
#

require "rails_helper"

RSpec.describe Dashboard::OverviewQuery do
  let(:today) { Date.new(2026, 6, 20) }
  let(:organization) { create(:organization) }
  let(:client) { create(:client, organization: organization) }
  let(:product) { create(:product, organization: organization) }

  def create_sale_with_item(organization:, client:, product:, status:, sale_date:, quantity:, unit_price:)
    create(
      :sale,
      organization: organization,
      client: client,
      status: status,
      sale_date: sale_date,
      sale_items_attributes: [
        { product_id: product.id, quantity: quantity, unit_price: unit_price }
      ]
    )
  end

  describe "monthly metrics" do
    before do
      create_sale_with_item(
        organization: organization,
        client: client,
        product: product,
        status: "completed",
        sale_date: today,
        quantity: 2,
        unit_price: 10
      )
      create_sale_with_item(
        organization: organization,
        client: client,
        product: product,
        status: "pending",
        sale_date: today.beginning_of_month,
        quantity: 3,
        unit_price: 5
      )
      create_sale_with_item(
        organization: organization,
        client: client,
        product: product,
        status: "cancelled",
        sale_date: today.end_of_month,
        quantity: 4,
        unit_price: 2.5
      )
      create_sale_with_item(
        organization: organization,
        client: client,
        product: product,
        status: "completed",
        sale_date: today.prev_month,
        quantity: 1,
        unit_price: 10
      )
    end

    subject(:dashboard) { described_class.new(organization: organization, today: today) }

    it "calculates revenue, volume, pending and cancelled metrics for the current month" do
      expect(dashboard.revenue).to eq(20)
      expect(dashboard.sales_count).to eq(3)
      expect(dashboard.pending_count).to eq(1)
      expect(dashboard.pending_value).to eq(15)
      expect(dashboard.cancelled_count).to eq(1)
      expect(dashboard.cancelled_value).to eq(10)
    end

    it "compares completed revenue and sales volume with the previous month" do
      expect(dashboard.revenue_change).to eq(100.0)
      expect(dashboard.sales_count_change).to eq(200.0)
    end

    it "counts clients and products from the organization" do
      expect(dashboard.clients_count).to eq(1)
      expect(dashboard.products_count).to eq(1)
    end

    it "does not include data from another organization" do
      other_organization = create(:organization)
      other_client = create(:client, organization: other_organization)
      other_product = create(:product, organization: other_organization)
      create_sale_with_item(
        organization: other_organization,
        client: other_client,
        product: other_product,
        status: "completed",
        sale_date: today,
        quantity: 100,
        unit_price: 100
      )

      expect(dashboard.revenue).to eq(20)
      expect(dashboard.sales_count).to eq(3)
      expect(dashboard.clients_count).to eq(1)
      expect(dashboard.products_count).to eq(1)
    end
  end

  describe "comparison without a previous-month base" do
    it "returns no percentage instead of an infinite or misleading value" do
      dashboard = described_class.new(organization: organization, today: today)

      expect(dashboard.revenue_change).to be_nil
      expect(dashboard.sales_count_change).to be_nil
    end
  end

  describe "lists" do
    it "limits recent and cancelled sales to five and orders them by date" do
      6.times do |index|
        create(
          :sale,
          :cancelled,
          organization: organization,
          client: client,
          sale_date: today.beginning_of_month + index.days
        )
      end
      previous_month_sale = create(
        :sale,
        :cancelled,
        organization: organization,
        client: client,
        sale_date: today.prev_month
      )

      dashboard = described_class.new(organization: organization, today: today)

      expect(dashboard.recent_sales.size).to eq(5)
      expect(dashboard.recent_sales.map(&:sale_date)).to eq((1..5).to_a.reverse.map { |day| today.beginning_of_month + day.days })
      expect(dashboard.cancelled_sales.size).to eq(5)
      expect(dashboard.cancelled_sales).not_to include(previous_month_sale)
    end

    it "ranks only products from completed sales in the current month" do
      most_sold = create(:product, organization: organization, name: "Alface Crespa")
      second_most_sold = create(:product, organization: organization, name: "Cebolinha Verde")
      pending_product = create(:product, organization: organization, name: "Tomate Cereja")
      previous_month_product = create(:product, organization: organization, name: "Rúcula Fresca")

      create_sale_with_item(
        organization: organization,
        client: client,
        product: most_sold,
        status: "completed",
        sale_date: today,
        quantity: 5,
        unit_price: 3
      )
      create_sale_with_item(
        organization: organization,
        client: client,
        product: second_most_sold,
        status: "completed",
        sale_date: today,
        quantity: 3,
        unit_price: 4
      )
      create_sale_with_item(
        organization: organization,
        client: client,
        product: pending_product,
        status: "pending",
        sale_date: today,
        quantity: 50,
        unit_price: 2
      )
      create_sale_with_item(
        organization: organization,
        client: client,
        product: previous_month_product,
        status: "completed",
        sale_date: today.prev_month,
        quantity: 50,
        unit_price: 2
      )

      dashboard = described_class.new(organization: organization, today: today)

      expect(dashboard.top_products.map(&:id)).to eq([ most_sold.id, second_most_sold.id ])
      expect(dashboard.top_products.map { |ranked_product| ranked_product.units_sold.to_i }).to eq([ 5, 3 ])
    end
  end
end

require 'rails_helper'

RSpec.describe "Sales Management", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let!(:membership) { create(:membership, user: user, organization: organization, role: "owner") }
  let!(:client) { create(:client, name: "Cliente Teste", organization: organization) }
  let!(:product) { create(:product, name: "Alface", price: 5.00, organization: organization) }

  before do
    driven_by(:rack_test)

    session = create(:session, user: user)
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(true)
    allow(Current).to receive(:session).and_return(session)
    allow(Current).to receive(:user) { User.find(user.id) }
    allow(Current).to receive(:organization) { Organization.find(organization.id) }
  end

  describe "creating a sale" do
    it "uses the product price when custom price is not enabled" do
      visit new_sale_path

      select "Cliente Teste", from: "sale_client_id"
      select "Alface", from: "sale_sale_items_attributes_0_product_id"
      fill_in "sale_sale_items_attributes_0_quantity", with: "3"
      click_button "Salvar Venda"

      expect(page).to have_content("Venda criada com sucesso")

      item = Sale.last.sale_items.sole
      expect(item.unit_price).to eq(5.00)
      expect(item.custom_price).to be(false)
      expect(Sale.last.total).to eq(15.00)
    end
  end

  describe "editing a sale" do
    let!(:sale) { create(:sale, organization: organization, client: client) }
    let!(:item) { create(:sale_item, sale: sale, product: product, quantity: 2, unit_price: 4.00, custom_price: true) }

    it "updates the custom price without changing the product price" do
      visit edit_sale_path(sale)

      fill_in "sale_sale_items_attributes_#{item.id}_unit_price", with: "3.50"
      click_button "Salvar Venda"

      expect(page).to have_content("Venda atualizada com sucesso")
      expect(item.reload.unit_price).to eq(3.50)
      expect(sale.reload.total).to eq(7.00)
      expect(product.reload.price).to eq(5.00)
    end

    it "goes back to the product price when custom price is disabled" do
      visit edit_sale_path(sale)

      uncheck "sale_sale_items_attributes_#{item.id}_custom_price"
      click_button "Salvar Venda"

      expect(page).to have_content("Venda atualizada com sucesso")
      expect(item.reload.unit_price).to eq(5.00)
      expect(item.custom_price).to be(false)
    end

    it "shows an error when the custom price is invalid" do
      visit edit_sale_path(sale)

      fill_in "sale_sale_items_attributes_#{item.id}_unit_price", with: "-2"
      click_button "Salvar Venda"

      expect(page).to have_content("Preço unitário do item deve ser maior que 0")
      expect(item.reload.unit_price).to eq(4.00)
    end
  end
end

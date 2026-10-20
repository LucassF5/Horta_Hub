require 'rails_helper'

RSpec.describe "Sales", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:role) { "owner" }
  let!(:membership) { create(:membership, user: user, organization: organization, role: role) }
  let!(:client) { create(:client, organization: organization) }
  let!(:product) { create(:product, organization: organization) }
  let!(:second_product) { create(:product, organization: organization) }
  let!(:sale) { create(:sale, organization: organization, client: client) }

  before do
    session = create(:session, user: user)
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(true)
    allow(Current).to receive(:session).and_return(session)
    allow(Current).to receive(:user).and_return(user)
    allow(Current).to receive(:organization).and_return(organization)
  end

  describe "GET /sales" do
    it "returns a successful response" do
      get sales_path
      expect(response).to have_http_status(:success)
    end

    it "renders the sales list" do
      get sales_path
      expect(response.body).to include("Vendas")
    end

    it "renders action links that navigate outside the turbo frame" do
      get sales_path

      expect(response.body).to include('data-turbo-frame="_top"')
    end

    it "shows each sale's seller" do
      sale.update!(seller: user)
      create(:sale, organization: organization, client: client)
      get sales_path
      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).to include(user.username, "Não vinculado")
    end
  end

  describe "GET /sales/:id" do
    it "returns a successful response" do
      get sale_path(sale)
      expect(response).to have_http_status(:success)
    end

    it "displays sale details" do
      get sale_path(sale)
      expect(response.body).to include("Venda ##{sale.id}")
    end

    it "displays responsible name when present" do
      sale.update!(responsible_name: "Lucas")

      get sale_path(sale)

      expect(response.body).to include("Responsável")
      expect(response.body).to include("Lucas")
    end

    it "displays the seller username" do
      sale.update!(seller: user)
      get sale_path(sale)
      expect(Capybara.string(response.body).find("dl").text).to include("Responsável", user.username)
    end
  end

  describe "GET /sales/new" do
    it "returns a successful response" do
      get new_sale_path
      expect(response).to have_http_status(:success)
    end

    it "renders the new sale form" do
      get new_sale_path
      expect(response.body).to include("Nova Venda")
    end

    it "tells the user that the sale needs at least one item" do
      get new_sale_path

      expect(response.body).to include("A venda deve ter ao menos um item.")
    end

    it "renders nested sale item fields with numeric indexes for Rails 8 params.expect" do
      get new_sale_path

      expect(response.body).to include("sale[sale_items_attributes][0][product_id]")
      expect(response.body).not_to include("sale[sale_items_attributes][new_0]")
    end

    it "shows the signed-in user as the read-only responsible" do
      get new_sale_path
      expect(Capybara.string(response.body).find("#sale_seller").text).to eq(user.username)
      expect(response.body).not_to include('name="sale[responsible_name]"', 'name="sale[seller_id]"')
    end
  end

  describe "POST /sales" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          client_id: client.id,
          sale_date: Date.current.to_s,
          status: "pending",
          responsible_name: "Lucas",
          notes: "Venda teste",
          sale_items_attributes: [
            { product_id: product.id, quantity: 2, unit_price: 10.50 }
          ]
        }
      end

      it "creates a new sale" do
        expect {
          post sales_path, params: { sale: valid_attributes }
        }.to change(Sale, :count).by(1)
      end

      it "creates sale items" do
        expect {
          post sales_path, params: { sale: valid_attributes }
        }.to change(SaleItem, :count).by(1)
      end

      it "records the signed-in user as the seller and ignores seller fields from the form" do
        other_user = create(:user)
        post sales_path, params: { sale: valid_attributes.merge(seller_id: other_user.id, responsible_name: "Lucas") }
        expect(Sale.last).to have_attributes(seller_id: user.id, responsible_name: nil)
      end

      it "creates a sale with multiple items and persists the calculated total" do
        product.update!(price: 10.50)
        second_product.update!(price: 4.25)
        attributes = valid_attributes.merge(
          sale_items_attributes: {
            "0" => { product_id: product.id, quantity: 2, unit_price: 10.50 },
            "1" => { product_id: second_product.id, quantity: 3, unit_price: 4.25 }
          }
        )

        post sales_path, params: { sale: attributes }

        created_sale = Sale.last
        expect(created_sale.sale_items.count).to eq(2)
        expect(created_sale.total).to eq(33.75)
      end

      it "redirects to the sales index" do
        post sales_path, params: { sale: valid_attributes }
        expect(response).to redirect_to(sales_path)
      end

      it "uses the product price when custom price is disabled" do
        product.update!(price: 8.00)
        attributes = valid_attributes.merge(
          sale_items_attributes: [
            { product_id: product.id, quantity: 2, unit_price: 99.00, custom_price: "0" }
          ]
        )

        post sales_path, params: { sale: attributes }

        item = Sale.last.sale_items.sole
        expect(item.unit_price).to eq(8.00)
        expect(item.custom_price).to be(false)
        expect(Sale.last.total).to eq(16.00)
      end

      it "ignores a manipulated unit price sent without the custom price flag" do
        product.update!(price: 8.00)
        attributes = valid_attributes.merge(
          sale_items_attributes: [
            { product_id: product.id, quantity: 2, unit_price: 0.01 }
          ]
        )

        post sales_path, params: { sale: attributes }

        item = Sale.last.sale_items.sole
        expect(item.unit_price).to eq(8.00)
        expect(item.custom_price).to be(false)
        expect(Sale.last.total).to eq(16.00)
      end

      it "uses the informed price when custom price is enabled without changing the product price" do
        product.update!(price: 8.00)
        attributes = valid_attributes.merge(
          sale_items_attributes: [
            { product_id: product.id, quantity: 2, unit_price: "6.50", custom_price: "1" }
          ]
        )

        post sales_path, params: { sale: attributes }

        item = Sale.last.sale_items.sole
        expect(item.unit_price).to eq(6.50)
        expect(item.custom_price).to be(true)
        expect(Sale.last.total).to eq(13.00)
        expect(product.reload.price).to eq(8.00)
      end

      it "sets a success notice" do
        post sales_path, params: { sale: valid_attributes }
        follow_redirect!
        expect(response.body).to include("Venda criada com sucesso")
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        { client_id: nil, sale_date: nil, status: "pending" }
      end

      it "does not create a new sale" do
        expect {
          post sales_path, params: { sale: invalid_attributes }
        }.not_to change(Sale, :count)
      end

      it "returns unprocessable entity status" do
        post sales_path, params: { sale: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "without sale items" do
      let(:attributes_without_items) do
        { client_id: client.id, sale_date: Date.current.to_s, status: "pending" }
      end

      it "does not create a sale without items" do
        expect {
          post sales_path, params: { sale: attributes_without_items }
        }.not_to change(Sale, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("A venda deve ter ao menos um item.")
      end

      it "does not create a sale when all items are blank" do
        attributes = attributes_without_items.merge(
          sale_items_attributes: [ { product_id: "", quantity: "", unit_price: "" } ]
        )

        expect {
          post sales_path, params: { sale: attributes }
        }.not_to change(Sale, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("A venda deve ter ao menos um item.")
      end
    end

    context "with an invalid custom price" do
      [ "", "-1", "abc" ].each do |unit_price|
        it "does not create the sale and shows an error for #{unit_price.inspect}" do
          attributes = {
            client_id: client.id,
            sale_date: Date.current.to_s,
            status: "pending",
            sale_items_attributes: [
              { product_id: product.id, quantity: 1, unit_price: unit_price, custom_price: "1" }
            ]
          }

          expect {
            post sales_path, params: { sale: attributes }
          }.not_to change(Sale, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("Preço unitário do item")
        end
      end
    end
  end

  describe "GET /sales/:id/edit" do
    it "returns a successful response" do
      get edit_sale_path(sale)
      expect(response).to have_http_status(:success)
    end

    it "renders the edit form" do
      get edit_sale_path(sale)
      expect(response.body).to include("Editar Venda")
    end

    it "renders persisted sale items with decimal unit prices" do
      create(:sale_item, sale: sale, product: product, quantity: 2, unit_price: 4.0, custom_price: true)

      get edit_sale_path(sale)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('value="4.0"')
    end

    it "renders the custom price toggle checked with an enabled price field" do
      item = create(:sale_item, sale: sale, product: product, unit_price: 4.0, custom_price: true)

      get edit_sale_path(sale)

      form = Capybara.string(response.body)
      expect(form).to have_checked_field("sale_sale_items_attributes_#{item.id}_custom_price")
      expect(form).to have_field("sale_sale_items_attributes_#{item.id}_unit_price", disabled: false, visible: :all)
    end

    it "renders the custom price toggle unchecked with a disabled price field" do
      item = create(:sale_item, sale: sale, product: product)

      get edit_sale_path(sale)

      form = Capybara.string(response.body)
      expect(form).to have_unchecked_field("sale_sale_items_attributes_#{item.id}_custom_price")
      expect(form).to have_field("sale_sale_items_attributes_#{item.id}_unit_price", disabled: true, visible: :all)
    end
  end

  describe "PATCH /sales/:id" do
    context "with valid parameters" do
      it "updates the sale" do
        patch sale_path(sale), params: { sale: { status: "completed" } }
        sale.reload
        expect(sale.status).to eq("completed")
      end

      it "redirects to the sales index" do
        patch sale_path(sale), params: { sale: { status: "completed" } }
        expect(response).to redirect_to(sales_path)
      end

      it "keeps the registered unit price when the product price changes later" do
        product.update!(price: 10.00)
        item = sale.sale_items.sole
        item.update!(product: product, quantity: 2)
        product.update!(price: 25.00)

        patch sale_path(sale), params: {
          sale: {
            notes: "Atualizada",
            sale_items_attributes: {
              "0" => { id: item.id, product_id: product.id, quantity: 2, custom_price: "0" }
            }
          }
        }

        expect(item.reload.unit_price).to eq(10.00)
        expect(sale.reload.total).to eq(20.00)
      end

      it "ignores a manipulated unit price when custom price stays disabled" do
        product.update!(price: 10.00)
        item = sale.sale_items.sole
        item.update!(product: product, quantity: 2)

        patch sale_path(sale), params: {
          sale: {
            sale_items_attributes: {
              "0" => { id: item.id, product_id: product.id, quantity: 3, unit_price: "0.01", custom_price: "0" }
            }
          }
        }

        expect(item.reload.unit_price).to eq(10.00)
        expect(item.custom_price).to be(false)
        expect(sale.reload.total).to eq(30.00)
      end

      it "ignores a manipulated unit price sent without the custom price flag" do
        product.update!(price: 10.00)
        item = sale.sale_items.sole
        item.update!(product: product, quantity: 2)

        patch sale_path(sale), params: {
          sale: {
            sale_items_attributes: {
              "0" => { id: item.id, product_id: product.id, quantity: 2, unit_price: "0.01" }
            }
          }
        }

        expect(item.reload.unit_price).to eq(10.00)
        expect(sale.reload.total).to eq(20.00)
      end

      it "uses the product price for a new item with a manipulated unit price" do
        product.update!(price: 10.00)
        second_product.update!(price: 5.00)
        item = sale.sale_items.sole
        item.update!(product: product, quantity: 2)

        patch sale_path(sale), params: {
          sale: {
            sale_items_attributes: {
              "0" => { id: item.id, product_id: product.id, quantity: 2 },
              "1" => { product_id: second_product.id, quantity: 4, unit_price: "0.01", custom_price: "0" }
            }
          }
        }

        new_item = sale.sale_items.find_by!(product: second_product)
        expect(new_item.unit_price).to eq(5.00)
        expect(sale.reload.total).to eq(40.00)
      end

      it "updates an item to use a custom price" do
        product.update!(price: 10.00)
        item = sale.sale_items.sole
        item.update!(product: product, quantity: 2)

        patch sale_path(sale), params: {
          sale: {
            sale_items_attributes: {
              "0" => { id: item.id, product_id: product.id, quantity: 2, unit_price: "7.25", custom_price: "1" }
            }
          }
        }

        expect(item.reload.unit_price).to eq(7.25)
        expect(sale.reload.total).to eq(14.50)
        expect(product.reload.price).to eq(10.00)
      end

      it "removes nested sale items marked for destruction" do
        item = create(:sale_item, sale: sale, product: product)

        expect {
          patch sale_path(sale), params: {
            sale: {
              sale_items_attributes: {
                "0" => { id: item.id, _destroy: "1" }
              }
            }
          }
        }.to change(SaleItem, :count).by(-1)
      end

      it "keeps the original seller" do
        seller = create(:user)
        create(:membership, user: seller, organization: organization, role: "manager")
        sale.update!(seller: seller, responsible_name: "VENDEDOR ORIGINAL")

        patch sale_path(sale), params: { sale: { status: "completed", seller_id: user.id, responsible_name: "Outro" } }

        expect(sale.reload).to have_attributes(seller_id: seller.id, responsible_name: "VENDEDOR ORIGINAL")
      end
    end

    context "with invalid parameters" do
      it "does not update the sale" do
        patch sale_path(sale), params: { sale: { sale_date: nil } }
        sale.reload
        expect(sale.sale_date).not_to be_nil
      end

      it "returns unprocessable entity status" do
        patch sale_path(sale), params: { sale: { sale_date: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not remove all sale items" do
        items_attributes = sale.sale_items.each_with_index.to_h do |item, index|
          [ index.to_s, { id: item.id, _destroy: "1" } ]
        end

        expect {
          patch sale_path(sale), params: { sale: { sale_items_attributes: items_attributes } }
        }.not_to change(SaleItem, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("A venda deve ter ao menos um item.")
      end
    end
  end

  describe "DELETE /sales/:id" do
    it "destroys the sale" do
      expect {
        delete sale_path(sale)
      }.to change(Sale, :count).by(-1)
    end

    it "redirects to the sales index" do
      delete sale_path(sale)
      expect(response).to redirect_to(sales_path)
    end
  end

  describe "GET /sales/sale_item_fields" do
    it "returns a turbo stream that appends a sale item row" do
      get sale_item_fields_sales_path, as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include('<turbo-stream action="append" target="sale_items">')
      expect(response.body).to include("sale[sale_items_attributes]")
      expect(response.body).to match(/sale\[sale_items_attributes\]\[\d+\]\[product_id\]/)
    end

    it "authorizes the existing sale when appending fields from the edit form" do
      get sale_item_fields_sales_path(sale_id: sale.id), as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).to include("sale_items")
    end
  end

  describe "sales filters" do
    let!(:pending_client) { create(:client, name: "Cliente Pendente", organization: organization) }
    let!(:completed_client) { create(:client, name: "Cliente Concluido", organization: organization) }
    let!(:pending_sale) { create(:sale, organization: organization, client: pending_client, status: "pending", sale_date: Date.new(2026, 1, 10)) }
    let!(:completed_sale) { create(:sale, organization: organization, client: completed_client, status: "completed", sale_date: Date.new(2026, 2, 10)) }

    it "filters by status" do
      get sales_path, params: { status: "completed" }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).to include("Cliente Concluido")
      expect(results_text).not_to include("Cliente Pendente")
    end

    it "filters by client" do
      get sales_path, params: { client_id: pending_client.id }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).to include("Cliente Pendente")
      expect(results_text).not_to include("Cliente Concluido")
    end

    it "filters by period" do
      get sales_path, params: { start_date: "2026-02-01", end_date: "2026-02-28" }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).to include("Cliente Concluido")
      expect(results_text).not_to include("Cliente Pendente")
    end

    it "keeps filters scoped to the current organization" do
      other_organization = create(:organization)
      other_client = create(:client, name: "Cliente Outra Organizacao", organization: other_organization)
      create(:sale, organization: other_organization, client: other_client, status: "completed", sale_date: Date.new(2026, 2, 10))

      get sales_path, params: { status: "completed" }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).to include("Cliente Concluido")
      expect(results_text).not_to include("Cliente Outra Organizacao")
    end

    it "ignores invalid dates" do
      get sales_path, params: { start_date: "invalid-date" }

      expect(response).to have_http_status(:success)
    end

    it "searches by client name" do
      get sales_path, params: { q: "pendente" }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).to include("Cliente Pendente")
      expect(results_text).not_to include("Cliente Concluido")
    end

    it "searches by responsible name" do
      completed_sale.update!(responsible_name: "Maria Feirante")

      get sales_path, params: { q: "feirante" }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).to include("Cliente Concluido")
      expect(results_text).not_to include("Cliente Pendente")
    end

    it "searches by seller username" do
      seller = create(:user, username: "joana_feira")
      create(:membership, user: seller, organization: organization, role: "manager")
      completed_sale.update!(seller: seller)

      get sales_path, params: { q: "joana" }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).to include("Cliente Concluido")
      expect(results_text).not_to include("Cliente Pendente")
    end

    it "combines search with filters" do
      get sales_path, params: { q: "cliente", status: "pending" }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).to include("Cliente Pendente")
      expect(results_text).not_to include("Cliente Concluido")
    end

    it "keeps search scoped to the current organization" do
      other_organization = create(:organization)
      other_client = create(:client, name: "Cliente Outra Organizacao", organization: other_organization)
      create(:sale, organization: other_organization, client: other_client)

      get sales_path, params: { q: "outra" }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).not_to include("Cliente Outra Organizacao")
    end

    it "sorts by sale date descending by default" do
      get sales_path

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text.index("Cliente Concluido")).to be < results_text.index("Cliente Pendente")
    end

    it "sorts by client name" do
      get sales_path, params: { sort: "client", direction: "asc" }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text.index("Cliente Concluido")).to be < results_text.index("Cliente Pendente")
    end

    it "keeps the current sort when filters are submitted" do
      get sales_path, params: { sort: "total", direction: "asc" }

      form = Capybara.string(response.body).find("form[action='#{sales_path}']")
      expect(form).to have_field("sort", type: :hidden, with: "total")
      expect(form).to have_field("direction", type: :hidden, with: "asc")
    end

    it "explains when no sale matches the filters" do
      get sales_path, params: { q: "inexistente" }

      results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
      expect(results_text).to include("Nenhuma venda encontrada")
      expect(results_text).to include("Limpar filtros")
    end
  end

  describe "sales empty state" do
    it "invites the user to register the first sale" do
      sale.destroy!

      get sales_path

      expect(response.body).to include("Registre a primeira venda")
    end

    it "keeps the results frame so filter submissions can replace it" do
      sale.destroy!

      get sales_path, headers: { "Turbo-Frame" => "sales_results" }

      expect(Capybara.string(response.body)).to have_css("turbo-frame#sales_results", text: "Registre a primeira venda")
    end
  end

  context "when not authenticated" do
    before do
      allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(false)
      allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(false)
    end

    it "redirects to login page" do
      get sales_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "when membership is viewer" do
    let(:role) { "viewer" }

    it "allows access to the sales index without management actions" do
      get sales_path

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Nova Venda", "Editar", "Apagar")
    end

    it "allows access to a sale without management actions" do
      get sale_path(sale)

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Editar", "Deletar")
    end

    it "denies access to the new sale form" do
      get new_sale_path

      expect(response).to redirect_to(root_path)
    end

    it "does not create a sale" do
      expect {
        post sales_path, params: {
          sale: {
            client_id: client.id,
            sale_date: Date.current,
            status: "pending"
          }
        }
      }.not_to change(Sale, :count)

      expect(response).to redirect_to(root_path)
    end

    it "denies access to the edit sale form" do
      get edit_sale_path(sale)

      expect(response).to redirect_to(root_path)
    end

    it "does not update a sale" do
      expect {
        patch sale_path(sale), params: { sale: { status: "completed" } }
      }.not_to change { sale.reload.status }

      expect(response).to redirect_to(root_path)
    end

    it "does not destroy a sale" do
      expect {
        delete sale_path(sale)
      }.not_to change(Sale, :count)

      expect(response).to redirect_to(root_path)
    end

    it "denies dynamic sale item fields" do
      get sale_item_fields_sales_path, as: :turbo_stream

      expect(response).to redirect_to(root_path)
    end
  end

  context "when sale belongs to another organization" do
    let(:other_org) { create(:organization) }
    let(:other_client) { create(:client, organization: other_org) }
    let(:other_sale) { create(:sale, organization: other_org, client: other_client) }

    it "raises not found for show" do
      get sale_path(other_sale)
      expect(response).to have_http_status(:not_found)
    end

    it "raises not found for edit" do
      get edit_sale_path(other_sale)
      expect(response).to have_http_status(:not_found)
    end

    it "raises not found for update" do
      patch sale_path(other_sale), params: { sale: { status: "completed" } }
      expect(response).to have_http_status(:not_found)
    end

    it "raises not found for destroy" do
      delete sale_path(other_sale)
      expect(response).to have_http_status(:not_found)
    end
  end
end

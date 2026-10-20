require 'rails_helper'

RSpec.describe "Products", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let!(:membership) { create(:membership, user: user, organization: organization, role: "owner") }
  let!(:product) { create(:product, organization: organization) }

  before do
    session = create(:session, user: user)
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(true)
    allow(Current).to receive(:session).and_return(session)
    allow(Current).to receive(:user).and_return(user)
    allow(Current).to receive(:organization).and_return(organization)
  end

  describe "GET /products" do
    it "returns a successful response" do
      get products_path
      expect(response).to have_http_status(:success)
    end

    it "renders the index view with products" do
      create_list(:product, 3, organization: organization)
      get products_path
      expect(response.body).to include("Produtos")
    end

    it "searches products by name" do
      create(:product, name: "Alface Crespa", organization: organization)
      create(:product, name: "Tomate Cereja", organization: organization)

      get products_path, params: { q: "alface" }

      expect(response.body).to include("Alface Crespa")
      expect(response.body).not_to include("Tomate Cereja")
    end

    it "treats LIKE wildcards in the search term literally" do
      create(:product, name: "Kit 50%", organization: organization)
      create(:product, name: "Kit 500", organization: organization)

      get products_path, params: { q: "50%" }

      expect(response.body).to include("Kit 50%")
      expect(response.body).not_to include("Kit 500")
    end

    it "does not search products from other organizations" do
      create(:product, name: "Alface Roxa", organization: create(:organization))

      get products_path, params: { q: "alface" }

      expect(response.body).not_to include("Alface Roxa")
    end

    it "sorts products by price" do
      create(:product, name: "Produto Caro", price: 90, organization: organization)
      create(:product, name: "Produto Barato", price: 1, organization: organization)

      get products_path, params: { sort: "price", direction: "desc" }

      expect(response.body.index("Produto Caro")).to be < response.body.index("Produto Barato")
    end

    it "ignores unknown sort columns" do
      get products_path, params: { sort: "organization_id; DROP TABLE products", direction: "sideways" }

      expect(response).to have_http_status(:success)
    end

    it "explains when the search finds nothing" do
      get products_path, params: { q: "inexistente" }

      expect(response.body).to include("Nenhum produto encontrado")
      expect(response.body).to include("Limpar busca")
    end

    it "invites the user to create the first product when there are none" do
      product.destroy!

      get products_path

      expect(response.body).to include("Cadastre o primeiro produto")
    end
  end

  describe "GET /products/:id" do
    it "returns a successful response" do
      get product_path(product)
      expect(response).to have_http_status(:success)
    end

    it "displays the product name" do
      get product_path(product)
      expect(response.body).to include(product.name)
    end

    it "displays the product price" do
      product.update!(price: 12.5)

      get product_path(product)

      expect(response.body).to include("Preço")
      expect(response.body).to include("R$ 12,50")
    end

    it "summarizes the product sales, ignoring cancelled ones in the totals" do
      client = create(:client, name: "Cliente do Produto", organization: organization)
      [ [ "completed", 3 ], [ "pending", 2 ], [ "cancelled", 10 ] ].each do |status, quantity|
        create(:sale, organization: organization, client: client, status: status,
          sale_items_attributes: [ { product_id: product.id, quantity: quantity, unit_price: 4, custom_price: true } ])
      end

      get product_path(product)

      details = Capybara.string(response.body).find("dl")
      expect(details).to have_css("div", text: "Vendas2")
      expect(details).to have_css("div", text: "Unidades vendidas5")
      expect(response.body).to include("Cliente do Produto")
      expect(response.body).to include("3 × R$ 4,00")
    end

    it "explains when the product was never sold" do
      get product_path(product)

      expect(response.body).to include("Este produto ainda não entrou em nenhuma venda.")
    end
  end

  describe "GET /products/new" do
    it "returns a successful response" do
      get new_product_path
      expect(response).to have_http_status(:success)
    end

    it "renders the new product form" do
      get new_product_path
      expect(response.body).to include("Novo Produto")
    end
  end

  describe "POST /products" do
    context "with valid parameters" do
      let(:valid_attributes) do
        { name: "New Product", price: 29.99 }
      end

      it "creates a new product" do
        expect {
          post products_path, params: { product: valid_attributes }
        }.to change(Product, :count).by(1)
      end

      it "redirects to the products index" do
        post products_path, params: { product: valid_attributes }
        expect(response).to redirect_to(products_path)
      end

      it "sets a success notice" do
        post products_path, params: { product: valid_attributes }
        follow_redirect!
        expect(response.body).to include("Produto criado com sucesso")
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        { name: "", price: nil }
      end

      it "does not create a new product" do
        expect {
          post products_path, params: { product: invalid_attributes }
        }.not_to change(Product, :count)
      end

      it "returns unprocessable entity status" do
        post products_path, params: { product: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "displays error messages" do
        post products_path, params: { product: invalid_attributes }
        expect(response.body).to include("erro")
      end
    end
  end

  describe "GET /products/:id/edit" do
    it "returns a successful response" do
      get edit_product_path(product)
      expect(response).to have_http_status(:success)
    end

    it "renders the edit form" do
      get edit_product_path(product)
      expect(response.body).to include("Editar Produto")
    end
  end

  describe "PATCH /products/:id" do
    context "with valid parameters" do
      let(:new_attributes) do
        { name: "Updated Product", price: 39.99 }
      end

      it "updates the product" do
        patch product_path(product), params: { product: new_attributes }
        product.reload
        expect(product.name).to eq("Updated Product")
        expect(product.price).to eq(39.99)
      end

      it "redirects to the products index" do
        patch product_path(product), params: { product: new_attributes }
        expect(response).to redirect_to(products_path)
      end

      it "sets a success notice" do
        patch product_path(product), params: { product: new_attributes }
        follow_redirect!
        expect(response.body).to include("Produto atualizado com sucesso")
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        { name: "", price: -10 }
      end

      it "does not update the product" do
        original_name = product.name
        patch product_path(product), params: { product: invalid_attributes }
        product.reload
        expect(product.name).to eq(original_name)
      end

      it "returns unprocessable entity status" do
        patch product_path(product), params: { product: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /products/:id" do
    it "destroys the product" do
      expect {
        delete product_path(product)
      }.to change(Product, :count).by(-1)
    end

    it "redirects to the products index" do
      delete product_path(product)
      expect(response).to redirect_to(products_path)
    end

    it "sets a success alert" do
      delete product_path(product)
      follow_redirect!
      expect(response.body).to include("Produto deletado com sucesso")
    end
  end

  context "when not authenticated" do
    before do
      allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(false)
      allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(false)
    end

    it "redirects to login page for index" do
      get products_path
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects to login page for show" do
      get product_path(product)
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects to login page for new" do
      get new_product_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "when product belongs to another organization" do
    let(:other_org) { create(:organization) }
    let(:other_product) { create(:product, organization: other_org) }

    it "raises not found for show" do
      get product_path(other_product)
      expect(response).to have_http_status(:not_found)
    end

    it "raises not found for edit" do
      get edit_product_path(other_product)
      expect(response).to have_http_status(:not_found)
    end

    it "raises not found for update" do
      patch product_path(other_product), params: { product: { name: "Hacked" } }
      expect(response).to have_http_status(:not_found)
    end

    it "raises not found for destroy" do
      delete product_path(other_product)
      expect(response).to have_http_status(:not_found)
    end

    it "does not list products from other organizations" do
      other_product # force creation
      get products_path
      expect(response.body).not_to include(other_product.name)
    end
  end

  context "when user has no organization" do
    before do
      user_without_org = create(:user)
      session = create(:session, user: user_without_org)
      allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(true)
      allow(Current).to receive(:session).and_return(session)
      allow(Current).to receive(:user).and_return(user_without_org)
      allow(Current).to receive(:organization).and_return(nil)
    end

    it "logs the user out" do
      get products_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end

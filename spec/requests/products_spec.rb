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
      get product_path(product)
      expect(response.body).to include("Preço")
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
end

require 'rails_helper'

RSpec.describe "Sales", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:role) { "owner" }
  let!(:membership) { create(:membership, user: user, organization: organization, role: role) }
  let!(:client) { create(:client, organization: organization) }
  let!(:product) { create(:product, organization: organization) }
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
  end

  describe "POST /sales" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          client_id: client.id,
          sale_date: Date.current.to_s,
          status: "pending",
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

      it "redirects to the sales index" do
        post sales_path, params: { sale: valid_attributes }
        expect(response).to redirect_to(sales_path)
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

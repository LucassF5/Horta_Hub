require 'rails_helper'

RSpec.describe "Clients", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let!(:membership) { create(:membership, user: user, organization: organization, role: "owner") }
  let!(:client) { create(:client, organization: organization) }

  before do
    session = create(:session, user: user)
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(true)
    allow(Current).to receive(:session).and_return(session)
    allow(Current).to receive(:user).and_return(user)
    allow(Current).to receive(:organization).and_return(organization)
  end

  describe "GET /clients" do
    it "returns a successful response" do
      get clients_path
      expect(response).to have_http_status(:success)
    end

    it "renders the clients list" do
      get clients_path
      expect(response.body).to include("Clientes")
    end

    it "displays the client name" do
      get clients_path
      expect(response.body).to include(client.name)
    end
  end

  describe "GET /clients/:id" do
    it "returns a successful response" do
      get client_path(client)
      expect(response).to have_http_status(:success)
    end

    it "displays client details" do
      get client_path(client)
      expect(response.body).to include(client.name)
      expect(response.body).to include("Tipo do cliente")
    end
  end

  describe "GET /clients/new" do
    it "returns a successful response" do
      get new_client_path
      expect(response).to have_http_status(:success)
    end

    it "renders the new client form" do
      get new_client_path
      expect(response.body).to include("Novo Cliente")
    end
  end

  describe "POST /clients" do
    context "with valid parameters" do
      let(:valid_attributes) do
        { name: "New Client", phone: "11999999999", client_type: "pessoa_fisica" }
      end

      it "creates a new client" do
        expect {
          post clients_path, params: { client: valid_attributes }
        }.to change(Client, :count).by(1)
      end

      it "redirects to the clients index" do
        post clients_path, params: { client: valid_attributes }
        expect(response).to redirect_to(clients_path)
      end

      it "sets a success notice" do
        post clients_path, params: { client: valid_attributes }
        follow_redirect!
        expect(response.body).to include("Cliente criado com sucesso")
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        { name: "", phone: "", client_type: "" }
      end

      it "does not create a new client" do
        expect {
          post clients_path, params: { client: invalid_attributes }
        }.not_to change(Client, :count)
      end

      it "returns unprocessable entity status" do
        post clients_path, params: { client: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "displays error messages" do
        post clients_path, params: { client: invalid_attributes }
        expect(response.body).to include("erro")
      end
    end
  end

  describe "GET /clients/:id/edit" do
    it "returns a successful response" do
      get edit_client_path(client)
      expect(response).to have_http_status(:success)
    end

    it "renders the edit form" do
      get edit_client_path(client)
      expect(response.body).to include("Editar cliente")
    end
  end

  describe "PATCH /clients/:id" do
    context "with valid parameters" do
      it "updates the client" do
        patch client_path(client), params: { client: { name: "Updated Client" } }
        client.reload
        expect(client.name).to eq("Updated Client")
      end

      it "redirects to the clients index" do
        patch client_path(client), params: { client: { name: "Updated Client" } }
        expect(response).to redirect_to(clients_path)
      end
    end

    context "with invalid parameters" do
      it "does not update the client" do
        original_name = client.name
        patch client_path(client), params: { client: { name: "" } }
        client.reload
        expect(client.name).to eq(original_name)
      end

      it "returns unprocessable entity status" do
        patch client_path(client), params: { client: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /clients/:id" do
    it "destroys the client" do
      expect {
        delete client_path(client)
      }.to change(Client, :count).by(-1)
    end

    it "redirects to the clients index" do
      delete client_path(client)
      expect(response).to redirect_to(clients_path)
    end
  end

  context "when not authenticated" do
    before do
      allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(false)
      allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(false)
    end

    it "redirects to login page" do
      get clients_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "when client belongs to another organization" do
    let(:other_org) { create(:organization) }
    let(:other_client) { create(:client, organization: other_org) }

    it "raises not found for show" do
      get client_path(other_client)
      expect(response).to have_http_status(:not_found)
    end

    it "raises not found for edit" do
      get edit_client_path(other_client)
      expect(response).to have_http_status(:not_found)
    end

    it "raises not found for update" do
      patch client_path(other_client), params: { client: { name: "Hacked" } }
      expect(response).to have_http_status(:not_found)
    end

    it "raises not found for destroy" do
      delete client_path(other_client)
      expect(response).to have_http_status(:not_found)
    end

    it "does not list clients from other organizations" do
      other_client # force creation
      get clients_path
      expect(response.body).not_to include(other_client.name)
    end
  end
end

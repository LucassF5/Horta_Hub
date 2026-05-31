require 'rails_helper'

RSpec.describe "Organizations", type: :request do
  describe "GET /organizations/new" do
    it "returns a successful response" do
      get new_organization_path
      expect(response).to have_http_status(:success)
    end

    it "renders the registration form" do
      get new_organization_path
      expect(response.body).to include("Criar Organização")
    end

    it "shows organization and user fields" do
      get new_organization_path
      expect(response.body).to include("Dados da Organização")
      expect(response.body).to include("Sua Conta (Administrador)")
    end

    it "shows login link" do
      get new_organization_path
      expect(response.body).to include("Fazer login")
    end
  end

  describe "POST /organizations" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          organization: { name: "Test Organization" },
          user: { username: "testuser", email_address: "test@example.com", password: "password123" }
        }
      end

      it "creates a new organization" do
        expect {
          post organizations_path, params: valid_params
        }.to change(Organization, :count).by(1)
      end

      it "creates a new user" do
        expect {
          post organizations_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "creates a membership with owner role" do
        post organizations_path, params: valid_params
        membership = Membership.last
        expect(membership.role).to eq("owner")
      end

      it "redirects to root after creation" do
        post organizations_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it "authenticates the user after creation" do
        post organizations_path, params: valid_params
        expect(cookies[:session_id]).to be_present
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          organization: { name: "" },
          user: { username: "", email_address: "", password: "" }
        }
      end

      it "does not create organization" do
        expect {
          post organizations_path, params: invalid_params
        }.not_to change(Organization, :count)
      end

      it "does not create user" do
        expect {
          post organizations_path, params: invalid_params
        }.not_to change(User, :count)
      end

      it "returns unprocessable entity status" do
        post organizations_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shows error messages" do
        post organizations_path, params: invalid_params
        expect(response.body).to include("Corrija os erros abaixo")
      end
    end

    context "with duplicate email" do
      let!(:existing_user) { create(:user, email_address: "taken@example.com") }

      it "does not create organization" do
        params = {
          organization: { name: "New Org" },
          user: { username: "newuser", email_address: "taken@example.com", password: "password123" }
        }
        expect {
          post organizations_path, params: params
        }.not_to change(Organization, :count)
      end
    end
  end

  context "when already authenticated" do
    let(:user) { create(:user, password: "password123") }

    before do
      post session_path, params: { email_address: user.email_address, password: "password123" }
    end

    it "redirects away from registration page" do
      get new_organization_path
      expect(response).to redirect_to(root_path)
    end
  end
end

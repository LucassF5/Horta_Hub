require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, password: "password123") }
  let!(:membership) { create(:membership, user: user, organization: organization, role: "owner") }

  describe "GET /session/new" do
    it "returns a successful response" do
      get new_session_path
      expect(response).to have_http_status(:success)
    end

    it "renders the login form" do
      get new_session_path
      expect(response.body).to include("Sign in")
    end

    it "shows link to create organization" do
      get new_session_path
      expect(response.body).to include("Criar Organização")
    end

    it "shows forgot password link" do
      get new_session_path
      expect(response.body).to include("Esqueceu a senha?")
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      it "authenticates and redirects" do
        post session_path, params: { email_address: user.email_address, password: "password123" }
        expect(response).to redirect_to(root_path)
      end

      it "sets the session cookie" do
        post session_path, params: { email_address: user.email_address, password: "password123" }
        expect(cookies[:session_id]).to be_present
      end
    end

    context "with invalid credentials" do
      it "returns unprocessable entity" do
        post session_path, params: { email_address: user.email_address, password: "wrong" }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shows error message" do
        post session_path, params: { email_address: user.email_address, password: "wrong" }
        expect(response.body).to include("Email ou senha inválidos")
      end

      it "does not authenticate with non-existent email" do
        post session_path, params: { email_address: "nobody@example.com", password: "password123" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /session" do
    before do
      post session_path, params: { email_address: user.email_address, password: "password123" }
    end

    it "logs out and redirects" do
      delete session_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "when already authenticated" do
    before do
      post session_path, params: { email_address: user.email_address, password: "password123" }
    end

    it "redirects away from login page" do
      get new_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end

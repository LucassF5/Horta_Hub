require 'rails_helper'

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user, email_address: "user@example.com") }

  describe "GET /passwords/new" do
    it "returns a successful response" do
      get new_password_path
      expect(response).to have_http_status(:success)
    end

    it "renders the password reset form" do
      get new_password_path
      expect(response.body).to include("Esqueceu sua senha?")
    end
  end

  describe "POST /passwords" do
    context "with an existing email" do
      it "redirects to login with notice" do
        post passwords_path, params: { email_address: user.email_address }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "with a non-existing email" do
      it "still redirects to login (no leak)" do
        post passwords_path, params: { email_address: "noone@example.com" }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the password update form with valid token" do
      token = user.password_reset_token
      get edit_password_path(token)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Atualize sua senha")
    end

    it "redirects with invalid token" do
      get edit_password_path("invalid-token")
      expect(response).to redirect_to(new_password_path)
    end
  end

  describe "PUT /passwords/:token" do
    let(:token) { user.password_reset_token }

    context "with matching passwords" do
      it "resets the password and redirects" do
        put password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "with non-matching passwords" do
      it "redirects back with alert" do
        put password_path(token), params: { password: "newpassword123", password_confirmation: "different" }
        expect(response).to redirect_to(edit_password_path(token))
      end
    end
  end
end

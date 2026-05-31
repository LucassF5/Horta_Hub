require 'rails_helper'

RSpec.describe "Home", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, password: "password123") }
  let!(:membership) { create(:membership, user: user, organization: organization) }

  before do
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "GET /" do
    it "returns a successful response" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "renders the home page" do
      get root_path
      expect(response.body).to include("Home")
    end
  end

  context "when not authenticated" do
    it "redirects to login" do
      delete session_path
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end

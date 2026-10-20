require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "user without an active organization" do
    it "logs out a user without organizations" do
      sign_in(create(:user))

      get root_path

      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(response.body).to include("Você não pertence a nenhuma organização.")
      expect(Session.count).to eq(0)
    end

    it "logs out a user whose only organization is inactive" do
      user = create(:user)
      create(:membership, user: user, organization: create(:organization, status: "inactive"))
      sign_in(user)

      get root_path

      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(response.body).to include("Você não pertence a nenhuma organização.")
      expect(Session.count).to eq(0)
    end
  end
end

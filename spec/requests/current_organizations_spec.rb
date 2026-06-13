require 'rails_helper'

RSpec.describe "Current organizations", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:organization) { create(:organization, name: "Horta Norte") }
  let(:other_organization) { create(:organization, name: "Horta Sul") }
  let!(:membership) { create(:membership, user: user, organization: organization, role: "owner") }
  let!(:other_membership) { create(:membership, user: user, organization: other_organization, role: "viewer") }
  let!(:product) { create(:product, name: "Alface Norte", organization: organization) }
  let!(:other_product) { create(:product, name: "Alface Sul", organization: other_organization) }

  before do
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "PATCH /current_organization" do
    it "switches the active organization for the session" do
      get products_path
      expect(response.body).to include(product.name)
      expect(response.body).not_to include(other_product.name)

      patch current_organization_path, params: { organization_id: other_organization.id }

      expect(response).to redirect_to(root_path)

      get products_path
      expect(response.body).to include(other_product.name)
      expect(response.body).not_to include(product.name)
    end

    it "does not switch to an organization the user does not belong to" do
      unrelated_organization = create(:organization)

      patch current_organization_path, params: { organization_id: unrelated_organization.id }

      expect(response).to redirect_to(root_path)

      get products_path
      expect(response.body).to include(product.name)
      expect(response.body).not_to include(other_product.name)
    end
  end
end

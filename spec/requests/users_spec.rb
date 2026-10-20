require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "DELETE /users/:id" do
    context "when the user is the sole owner of an organization" do
      let!(:membership) { create(:membership, user: user, organization: organization, role: "owner") }

      it "keeps the account, the membership and the session" do
        expect {
          delete user_path(user)
        }.not_to change(User, :count)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Você é o único dono de uma organização; transfira a posse antes de excluir a conta.")
        expect(Membership.exists?(membership.id)).to be(true)
        expect(user.sessions.count).to eq(1)
        expect(cookies[:session_id]).to be_present
      end
    end

    context "when the user is not the sole owner" do
      before do
        create(:membership, organization: organization)
        create(:membership, :viewer, user: user, organization: organization)
      end

      it "deletes the account and ends the session" do
        expect {
          delete user_path(user)
        }.to change(User, :count).by(-1)

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq("Conta excluída com sucesso.")
        expect(cookies[:session_id]).to be_blank
      end
    end
  end
end

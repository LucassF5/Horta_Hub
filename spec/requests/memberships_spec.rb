require "rails_helper"

RSpec.describe "Memberships", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:role) { "owner" }
  let!(:membership) { create(:membership, user: user, organization: organization, role: role) }
  let(:new_member_params) do
    { member: { username: "novo_funcionario", email_address: "novo@example.com", role: "viewer" } }
  end

  def extract_password(body)
    body[/value="([A-Za-z0-9]{8})"/, 1]
  end

  context "with stubbed authentication" do
    before do
      session = create(:session, user: user)
      allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(true)
      allow(Current).to receive(:session).and_return(session)
      allow(Current).to receive(:user).and_return(user)
      allow(Current).to receive(:organization).and_return(organization)
    end

    describe "GET /memberships" do
      let!(:member) { create(:membership, :viewer, organization: organization) }

      it "lists the organization members for an owner" do
        get memberships_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Funcionários")
        expect(response.body).to include(member.user.email_address)
        expect(response.body).to include("Dono")
      end

      it "orders members by role rank, then username" do
        create(:membership, :viewer, organization: organization, user: create(:user, username: "aaa_viewer"))
        create(:membership, :admin, organization: organization, user: create(:user, username: "zzz_admin"))

        get memberships_path

        positions = [ user.username, "zzz_admin", "aaa_viewer", member.user.username ].map { |name| response.body.index(name) }
        expect(positions).to eq(positions.sort)
      end

      it "does not list members of other organizations" do
        outsider = create(:membership, organization: create(:organization))

        get memberships_path

        expect(response.body).not_to include(outsider.user.email_address)
      end
    end

    %w[manager viewer].each do |unauthorized_role|
      context "when the user is a #{unauthorized_role}" do
        let(:role) { unauthorized_role }

        it "refuses GET /memberships" do
          get memberships_path

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include("Você não tem permissão")
        end

        it "refuses GET /memberships/new" do
          get new_membership_path

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include("Você não tem permissão")
        end

        it "hides the Funcionários sidebar item" do
          get clients_path

          expect(response.body).not_to include("Funcionários")
        end
      end
    end

    %w[owner admin].each do |manager_role|
      context "when the user is an #{manager_role}" do
        let(:role) { manager_role }

        it "shows the Funcionários sidebar item" do
          get clients_path

          expect(response.body).to include("Funcionários")
        end
      end
    end

    describe "GET /memberships/new" do
      it "renders the form with the assignable roles" do
        get new_membership_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Novo funcionário")
        expect(response.body).to include("Dono", "Administrador", "Gerente", "Visualizador")
      end
    end

    describe "POST /memberships" do
      context "with a new account" do
        it "creates the user and shows the generated password once" do
          expect {
            post memberships_path, params: new_member_params
          }.to change(User, :count).by(1).and change(Membership, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(response.headers["Cache-Control"]).to include("no-store")
          expect(response.body).to include("Funcionário adicionado com sucesso.")
          expect(response.body).to include("Esta senha não será mostrada novamente")
          expect(extract_password(response.body)).to be_present
        end

        it "never stores the generated password in the flash" do
          post memberships_path, params: new_member_params
          password = extract_password(response.body)

          get memberships_path

          expect(response.body).not_to include(password)
        end

        it "refuses to add the same member twice" do
          post memberships_path, params: new_member_params

          expect {
            post memberships_path, params: new_member_params
          }.not_to change(Membership, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("já pertence a esta organização")
        end

        it "re-renders the form with Portuguese errors when invalid" do
          expect {
            post memberships_path, params: { member: { username: "", email_address: "", role: "viewer" } }
          }.not_to change(User, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("Nome de usuário não pode ficar em branco")
        end
      end

      context "with an email from another organization" do
        let!(:existing_user) { create(:user, :with_organization) }

        it "adds the existing account without creating a user" do
          expect {
            post memberships_path, params: { member: { username: "", email_address: existing_user.email_address, role: "viewer" } }
          }.not_to change(User, :count)

          expect(response).to redirect_to(memberships_path)
          expect(flash[:notice]).to eq("Usuário já existente adicionado à organização.")
          expect(organization.memberships.exists?(user: existing_user)).to be(true)
        end
      end

      context "when an admin assigns a role above their own" do
        let(:role) { "admin" }

        it "refuses the owner role" do
          expect {
            post memberships_path, params: { member: new_member_params[:member].merge(role: "owner") }
          }.not_to change(User, :count)

          expect(response).to redirect_to(root_path)
          expect(Membership.count).to eq(1)
        end

        it "refuses an unknown role without erroring" do
          expect {
            post memberships_path, params: { member: new_member_params[:member].merge(role: "superuser") }
          }.not_to change(Membership, :count)

          expect(response).to redirect_to(root_path)
          expect(User.count).to eq(1)
        end
      end
    end
  end

  context "with a real session" do
    before { sign_in(user) }

    it "lets the new member log in with the generated password" do
      post memberships_path, params: new_member_params
      password = extract_password(response.body)
      sign_out

      post session_path, params: { email_address: "novo@example.com", password: password }

      expect(response).to redirect_to(root_path)
    end
  end
end

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
          expect(response.body).to include("data-turbo-temporary")
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

    describe "member actions" do
      let!(:viewer) { create(:membership, :viewer, organization: organization) }
      let(:foreign_membership) { create(:membership, :viewer, organization: create(:organization)) }

      def create_sessions_for(member, count: 2)
        create_list(:session, count, user: member.user)
      end

      describe "GET /memberships/:id/edit" do
        it "renders the role select for an owner" do
          get edit_membership_path(viewer)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Editar funcionário")
          expect(response.body).to include("Dono", "Administrador", "Gerente", "Visualizador")
        end

        context "when an admin edits an owner" do
          let(:role) { "admin" }
          let!(:owner_member) { create(:membership, organization: organization) }

          it "refuses access" do
            get edit_membership_path(owner_member)

            expect(response).to redirect_to(root_path)
          end
        end
      end

      describe "PATCH /memberships/:id" do
        it "lets an owner change a viewer to manager" do
          patch membership_path(viewer), params: { membership: { role: "manager" } }

          expect(response).to redirect_to(memberships_path)
          expect(flash[:notice]).to eq("Cargo atualizado com sucesso.")
          expect(viewer.reload).to be_manager
        end

        it "refuses changing the owner's own membership" do
          patch membership_path(membership), params: { membership: { role: "admin" } }

          expect(response).to redirect_to(root_path)
          expect(membership.reload).to be_owner
        end

        it "returns 404 for a membership of another organization" do
          patch membership_path(foreign_membership), params: { membership: { role: "manager" } }

          expect(response).to have_http_status(:not_found)
          expect(foreign_membership.reload).to be_viewer
        end

        context "when an admin promotes a viewer to owner" do
          let(:role) { "admin" }

          it "refuses the change" do
            patch membership_path(viewer), params: { membership: { role: "owner" } }

            expect(response).to redirect_to(root_path)
            expect(viewer.reload).to be_viewer
          end
        end
      end

      describe "DELETE /memberships/:id" do
        it "removes a sole-organization viewer and ends their sessions" do
          create_sessions_for(viewer)

          expect {
            delete membership_path(viewer)
          }.to change(Membership, :count).by(-1).and change(User, :count).by(0)

          expect(response).to redirect_to(memberships_path)
          expect(response).to have_http_status(:see_other)
          expect(flash[:notice]).to eq("Funcionário removido da organização.")
          expect(viewer.user.sessions.count).to eq(0)
        end

        it "keeps the sessions of a viewer who belongs to another active organization" do
          create(:membership, :viewer, user: viewer.user, organization: create(:organization))
          create_sessions_for(viewer)

          delete membership_path(viewer)

          expect(response).to redirect_to(memberships_path)
          expect(viewer.user.sessions.count).to eq(2)
        end

        it "returns 404 for a membership of another organization" do
          foreign_membership

          expect {
            delete membership_path(foreign_membership)
          }.not_to change(Membership, :count)

          expect(response).to have_http_status(:not_found)
        end
      end

      describe "POST /memberships/:id/reset_password" do
        it "shows a new password for a sole-organization viewer and ends their sessions" do
          create_sessions_for(viewer)

          post reset_password_membership_path(viewer)

          expect(response).to have_http_status(:ok)
          expect(response.headers["Cache-Control"]).to include("no-store")
          expect(response.body).to include("Nova senha gerada com sucesso.")
          expect(response.body).to include("data-turbo-temporary")
          password = extract_password(response.body)
          expect(viewer.user.reload.authenticate(password)).to be_truthy
          expect(viewer.user.sessions.count).to eq(0)
        end

        it "refuses a viewer who belongs to another organization" do
          create(:membership, :viewer, user: viewer.user, organization: create(:organization))

          post reset_password_membership_path(viewer)

          expect(response).to redirect_to(root_path)
          expect(viewer.user.reload.authenticate("password123")).to be_truthy
        end

        it "returns 404 for a membership of another organization" do
          post reset_password_membership_path(foreign_membership)

          expect(response).to have_http_status(:not_found)
          expect(foreign_membership.user.reload.authenticate("password123")).to be_truthy
        end
      end

      describe "GET /memberships row actions" do
        it "shows the actions for a viewer and none on the owner's own row" do
          get memberships_path

          expect(response.body).to include("Editar", "Remover", "Gerar nova senha")
          expect(response.body).to include(%(href="#{edit_membership_path(viewer)}"))
          expect(response.body).to include(%(action="#{membership_path(viewer)}"))
          expect(response.body).to include(%(action="#{reset_password_membership_path(viewer)}"))
          expect(response.body).to include('data-controller="confirm"')
          expect(response.body).not_to include(%(href="#{edit_membership_path(membership)}"))
          expect(response.body).not_to include(%(action="#{membership_path(membership)}"))
          expect(response.body).not_to include(%(action="#{reset_password_membership_path(membership)}"))
        end

        context "when the user is an admin" do
          let(:role) { "admin" }
          let!(:owner_member) { create(:membership, organization: organization) }

          it "shows no actions on an owner's row" do
            get memberships_path

            expect(response.body).to include(%(href="#{edit_membership_path(viewer)}"))
            expect(response.body).not_to include(%(href="#{edit_membership_path(owner_member)}"))
            expect(response.body).not_to include(%(action="#{membership_path(owner_member)}"))
            expect(response.body).not_to include(%(action="#{reset_password_membership_path(owner_member)}"))
          end
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

require "rails_helper"

RSpec.describe "Reports", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:organization) { create(:organization) }
  let(:user) { create(:user, password: "password123") }
  let(:role) { "manager" }
  let!(:membership) { create(:membership, user: user, organization: organization, role: role) }
  let(:product) { create(:product, organization: organization) }

  before { post session_path, params: { email_address: user.email_address, password: "password123" } }

  %w[owner admin manager].each do |role_name|
    context "when membership is #{role_name}" do
      let(:role) { role_name }

      it "renders the report" do
        get report_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Relatórios", "Receita", "Vendas concluídas", "Unidades vendidas", "Ticket médio", "Pendentes", "Canceladas")
      end
    end
  end

  context "when membership is viewer" do
    let(:role) { "viewer" }

    it "redirects to the dashboard with the permission alert" do
      get report_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Você não tem permissão para realizar esta ação.")
    end

    it "hides the sidebar link" do
      get root_path
      expect(response.body).not_to include('href="/report"')
    end
  end

  it "shows the sidebar link to a manager" do
    get root_path
    expect(response.body).to include('href="/report"')
  end

  it "shows the selected month with its comparison" do
    travel_to(Time.zone.local(2026, 10, 20, 12)) do
      create_report_sale(organization: organization, date: Date.new(2026, 7, 20), items: [ [ product, 3, 10 ] ])
      create_report_sale(organization: organization, date: Date.new(2026, 8, 20), items: [ [ product, 5, 10 ] ])

      get report_path(month: "2026-08")

      expect(response.body).to include("R$ 50,00", "▲ 66,7%", "vs jul/2026", '<option value="2026-08" selected')
    end
  end

  it "falls back to defaults on invalid filters and never shows another organization" do
    travel_to(Time.zone.local(2026, 10, 20, 12)) do
      other = create(:organization)
      other_product = create(:product, organization: other)
      create_report_sale(organization: other, date: Date.new(2026, 10, 5), items: [ [ other_product, 1, 999 ] ])

      get report_path(month: "abc", product_id: other_product.id, seller: "garbage")

      expect(response).to have_http_status(:success)
      expect(response.body).to include('<option value="2026-10" selected')
      expect(response.body).not_to include("R$ 999,00")
    end
  end

  it "ignores a seller key from outside the organization" do
    travel_to(Time.zone.local(2026, 10, 20, 12)) do
      foreign_user = create(:membership, organization: create(:organization)).user
      create_report_sale(organization: organization, date: Date.new(2026, 10, 5), items: [ [ product, 3, 10 ] ])

      get report_path(seller: "user:#{foreign_user.id}")

      expect(response).to have_http_status(:success)
      expect(response.body).to include("R$ 30,00")
    end
  end

  it "renders an organization without sales" do
    get report_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("R$ 0,00", "Sem base em")
  end
end

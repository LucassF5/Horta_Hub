require "rails_helper"

RSpec.describe "Home", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, password: "password123") }
  let(:role) { "owner" }
  let!(:membership) { create(:membership, user: user, organization: organization, role: role) }

  before do
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  def create_sale_with_item(client:, product:, status:, sale_date:, quantity:, unit_price:)
    create(
      :sale,
      organization: client.organization,
      client: client,
      status: status,
      sale_date: sale_date,
      sale_items_attributes: [
        { product_id: product.id, quantity: quantity, unit_price: unit_price }
      ]
    )
  end

  describe "GET /" do
    it "renders the operational dashboard without scaffold content" do
      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Dashboard")
      expect(response.body).to include("Receita do mês")
      expect(response.body).to include("Vendas do mês")
      expect(response.body).to include("Pendentes")
      expect(response.body).to include("Canceladas")
      expect(response.body).not_to include("Home::Index")
      expect(response.body).not_to include("Find me in app/views/home/index.rb")
    end

    it "renders useful empty states and zeroed metrics" do
      get root_path

      expect(response.body).to include("R$ 0,00")
      expect(response.body).to include("Sem base no mês anterior")
      expect(response.body).to include("Nenhuma venda cadastrada ainda.")
      expect(response.body).to include("Ainda não há produtos em vendas concluídas neste mês.")
      expect(response.body).to include("Nenhuma venda cancelada neste mês.")
    end

    it "renders monthly calculations and comparisons from the query through the view" do
      client = create(:client, organization: organization, name: "Cliente do Fluxo Completo")
      product = create(:product, organization: organization, name: "Alface do Fluxo Completo")

      create_sale_with_item(
        client: client,
        product: product,
        status: "completed",
        sale_date: Date.current,
        quantity: 3,
        unit_price: 10
      )
      create_sale_with_item(
        client: client,
        product: product,
        status: "pending",
        sale_date: Date.current,
        quantity: 2,
        unit_price: 10
      )
      create_sale_with_item(
        client: client,
        product: product,
        status: "cancelled",
        sale_date: Date.current,
        quantity: 1,
        unit_price: 5
      )
      create_sale_with_item(
        client: client,
        product: product,
        status: "completed",
        sale_date: Date.current.prev_month,
        quantity: 1,
        unit_price: 10
      )

      get root_path

      rendered_page = Capybara.string(response.body)

      expect(response).to have_http_status(:success)
      expect(rendered_page).to have_css("#metric-revenue", text: "R$ 30,00")
      expect(rendered_page).to have_css("#metric-revenue", text: "+200,0% vs. mês anterior")
      expect(rendered_page).to have_css("#metric-sales", text: "3")
      expect(rendered_page).to have_css("#metric-sales", text: "+200,0% vs. mês anterior")
      expect(rendered_page).to have_css("#metric-pending", text: "R$ 20,00 em aberto")
      expect(rendered_page).to have_css("#metric-cancelled", text: "R$ 5,00 cancelados")
      expect(rendered_page).to have_css("#metric-clients", text: "1")
      expect(rendered_page).to have_css("#metric-products", text: "1")
      expect(response.body).to include("Cliente do Fluxo Completo")
      expect(response.body).to include("Alface Do Fluxo Completo")
      expect(response.body).to include("Concluída")
      expect(response.body).to include("Pendente")
      expect(response.body).to include("Cancelada")
      expect(response.body).to include("3 unidades")
    end

    it "renders data from the current organization and excludes other organizations" do
      current_client = create(:client, organization: organization, name: "Cliente da Horta Atual")
      current_product = create(:product, organization: organization, name: "Alface da Horta Atual")
      create(
        :sale,
        organization: organization,
        client: current_client,
        status: "completed",
        sale_date: Date.current,
        sale_items_attributes: [
          { product_id: current_product.id, quantity: 2, unit_price: 10 }
        ]
      )

      other_organization = create(:organization)
      other_client = create(:client, organization: other_organization, name: "Cliente de Outra Horta")
      other_product = create(:product, organization: other_organization, name: "Produto de Outra Horta")
      create(
        :sale,
        organization: other_organization,
        client: other_client,
        status: "completed",
        sale_date: Date.current,
        sale_items_attributes: [
          { product_id: other_product.id, quantity: 50, unit_price: 100 }
        ]
      )

      get root_path

      expect(response.body).to include("Cliente da Horta Atual")
      expect(response.body).to include("Alface Da Horta Atual")
      expect(response.body).to include("R$ 20,00")
      expect(response.body).not_to include("Cliente de Outra Horta")
      expect(response.body).not_to include("Produto de Outra Horta")
      expect(response.body).not_to include("R$ 5.000,00")
    end

    it "shows creation shortcuts to members who can manage records" do
      get root_path

      expect(response.body).to include("Nova venda")
      expect(response.body).to include("Novo cliente")
      expect(response.body).to include("Novo produto")
    end

    context "when membership is viewer" do
      let(:role) { "viewer" }

      it "does not show creation shortcuts" do
        get root_path

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("Nova venda")
        expect(response.body).not_to include("Novo cliente")
        expect(response.body).not_to include("Novo produto")
      end
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

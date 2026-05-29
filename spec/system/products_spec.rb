require 'rails_helper'

RSpec.describe "Products Management", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let!(:membership) { create(:membership, user: user, organization: organization, role: "owner") }

  before do
    driven_by(:rack_test)

    # Simular autenticação para testes de sistema
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(true)
    allow(Current).to receive(:session).and_return(create(:session, user: user))
  end

  describe "viewing products" do
    let!(:product1) { create(:product, name: "Product One", price: 10.00, organization: organization) }
    let!(:product2) { create(:product, name: "Product Two", price: 20.00, organization: organization) }

    it "displays all products" do
      visit products_path

      expect(page).to have_content("Produtos")
      expect(page).to have_content("Product One")
      expect(page).to have_content("Product Two")
      expect(page).to have_content("R$ 10,00")
      expect(page).to have_content("R$ 20,00")
    end

    it "shows product details" do
      visit products_path
      click_link "Ver", match: :first

      expect(page).to have_content(product1.name)
      expect(page).to have_content("Preço")
    end
  end

  describe "creating a product" do
    it "successfully creates a new product" do
      visit products_path
      click_link "Novo Produto"

      expect(page).to have_content("Novo Produto")

      fill_in "product[name]", with: "New Test Product"
      fill_in "product[price]", with: "15.99"

      click_button "Salvar produto"

      expect(page).to have_content("Produto criado com sucesso")
      expect(page).to have_content("New Test Product")
    end

    it "displays validation errors for invalid data" do
      visit new_product_path

      fill_in "product[name]", with: ""
      fill_in "product[price]", with: ""

      click_button "Salvar produto"

      expect(page).to have_content("erro")
    end

    it "validates minimum name length" do
      visit new_product_path

      fill_in "product[name]", with: "ab"
      fill_in "product[price]", with: "10"

      click_button "Salvar produto"

      expect(page).to have_content("erro")
    end
  end

  describe "editing a product" do
    let!(:product) { create(:product, name: "Original Name", price: 25.00, organization: organization) }

    it "successfully updates a product" do
      visit products_path
      click_link "Editar", match: :first

      expect(page).to have_content("Editar Produto")

      fill_in "product[name]", with: "Updated Name"
      fill_in "product[price]", with: "30.00"

      click_button "Salvar produto"

      expect(page).to have_content("Produto atualizado com sucesso")
      expect(page).to have_content("Updated Name")
    end

    it "displays validation errors for invalid updates" do
      visit edit_product_path(product)

      fill_in "product[name]", with: ""

      click_button "Salvar produto"

      expect(page).to have_content("erro")
    end
  end

  describe "deleting a product" do
    let!(:product) { create(:product, name: "Product to Delete", organization: organization) }

    it "successfully deletes a product" do
      visit products_path

      expect(page).to have_content("Product to Delete")

      # O botão de apagar tem confirmação, mas em testes rack_test não processa JavaScript
      # então vamos aceitar que o produto será deletado
      expect {
        click_button "Apagar", match: :first
      }.to change(Product, :count).by(-1)

      expect(page).to have_content("Produto deletado com sucesso")
      expect(page).not_to have_content("Product to Delete")
    end
  end

  describe "navigation" do
    let!(:product) { create(:product, organization: organization) }

    it "navigates back from show page to index" do
      visit product_path(product)
      click_link "Voltar para Produtos"

      expect(page).to have_content("Produtos")
      expect(page).to have_current_path(products_path)
    end

    it "navigates from index to new product page" do
      visit products_path
      click_link "Novo Produto"

      expect(page).to have_content("Novo Produto")
      expect(page).to have_current_path(new_product_path)
    end

    it "navigates from index to edit page" do
      visit products_path
      click_link "Editar", match: :first

      expect(page).to have_content("Editar Produto")
    end
  end

  describe "product cards display" do
    let!(:product) { create(:product, name: "Test Product", price: 15.50, organization: organization) }

    it "displays product information in cards" do
      visit products_path

      within(".grid") do
        expect(page).to have_content("Test Product")
        expect(page).to have_content("Valor: R$ 15,50")
      end
    end

    it "displays action buttons for each product" do
      visit products_path

      within(".grid") do
        expect(page).to have_link("Ver")
        expect(page).to have_link("Editar")
        expect(page).to have_button("Apagar")
      end
    end
  end
end

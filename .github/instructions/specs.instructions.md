---
description: "Use ao criar ou editar specs RSpec. Cobre model specs, request specs, factories, matchers e autenticação em testes."
applyTo: "spec/**/*.rb"
---

# Padrão de Specs (RSpec)

## Tipos de Spec

- **Model specs**: `spec/models/resource_spec.rb` — validações, associations, métodos
- **Request specs**: `spec/requests/resources_spec.rb` — HTTP responses, redirects, flash
- **System specs**: `spec/system/` — testes E2E com Capybara (usar quando necessário)
- **Factories**: `spec/factories/resources.rb`

## Convenções

- `sign_in(user)` antes de requests autenticados (helper em `spec/support/authentication_helper.rb`)
- `Faker` para dados dinâmicos
- `FactoryBot` com sintaxe curta: `create(:resource)`, `build(:resource)`
- `shoulda-matchers` para associations e validações
- Criar factory e model spec **sempre** ao adicionar um novo model

## Modelo de Factory

```ruby
FactoryBot.define do
  factory :resource do
    sequence(:name) { |n| "Resource #{n}" }
    price { Faker::Commerce.price(range: 1.0..100.0) }
    association :organization

    trait :expensive do
      price { Faker::Commerce.price(range: 100.0..500.0) }
    end

    trait :inactive do
      status { "inactive" }
    end
  end
end
```

## Modelo de Model Spec

```ruby
RSpec.describe Resource, type: :model do
  describe "associations" do
    it { should belong_to(:organization) }
    it { should have_many(:items).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:resource) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(50) }
    it { should validate_uniqueness_of(:name).scoped_to(:organization_id) }
  end

  describe "normalizations" do
    it "normaliza o nome" do
      resource = create(:resource, name: "  Teste  ")
      expect(resource.name).to eq("Teste")
    end
  end
end
```

## Modelo de Request Spec

```ruby
RSpec.describe "Resources", type: :request do
  let(:user) { create(:user, :with_organization) }
  let(:organization) { user.organization }

  before { sign_in(user) }

  describe "GET /resources" do
    it "retorna sucesso" do
      get resources_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /resources" do
    let(:valid_params) { { resource: { name: "Novo Recurso", price: 10.0 } } }
    let(:invalid_params) { { resource: { name: "", price: -1 } } }

    context "com parâmetros válidos" do
      it "cria o recurso" do
        expect {
          post resources_path, params: valid_params
        }.to change(Resource, :count).by(1)
      end

      it "redireciona com flash" do
        post resources_path, params: valid_params
        expect(response).to redirect_to(resources_path)
        follow_redirect!
        expect(response.body).to include("criado com sucesso")
      end
    end

    context "com parâmetros inválidos" do
      it "retorna unprocessable_entity" do
        post resources_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /resources/:id" do
    let!(:resource) { create(:resource, organization: organization) }

    it "remove o recurso" do
      expect {
        delete resource_path(resource)
      }.to change(Resource, :count).by(-1)
    end
  end
end
```

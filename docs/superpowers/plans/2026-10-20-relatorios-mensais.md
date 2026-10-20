# Relatórios mensais e vínculo do vendedor — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Registrar o usuário que fez cada venda e criar a página Relatórios (owner, admin, manager) com escolha de mês, comparativos em % e em quantidade, evolução no ano, produtos e vendedores.

**Architecture:** `sales.seller_id` (FK opcional para `users`), com `responsible_name` em texto como reserva. Os números saem de objetos de consulta pequenos em `app/queries/reports/` (período, escopo filtrado, resumo, série do ano, produtos, vendedores), reunidos por `Reports::MonthlyReport` e exibidos por componentes Phlex em `app/views/reports/`. Toda agregação é SQL sobre `sale_items` unidos a `sales`.

**Tech Stack:** Rails 8.1, SQLite, Phlex + RubyUI, Tailwind, Stimulus (`submit-on-change` já existe), Action Policy, RSpec + FactoryBot + shoulda-matchers.

**Spec:** `docs/superpowers/specs/2026-10-20-relatorios-mensais-design.md`

## Global Constraints

- Sem gems, bibliotecas JS ou biblioteca de gráficos novas. Gráfico em HTML/CSS (CSP está desligada; `style` inline é permitido).
- Views só em Phlex. Identificadores em inglês; textos visíveis em pt-BR; comentários em pt-BR e só quando necessário.
- Toda consulta escopada pela organização recebida (`Current.organization` nos controllers). Única exceção: o backfill global da Task 3.
- Relatórios: só owner, admin e manager (`can_manage?`). Viewer recebe o tratamento existente: redirect para `root_path` com "Você não tem permissão para realizar esta ação."
- Receita, Vendas concluídas, Unidades vendidas, Ticket médio, produtos, vendedores e gráfico do ano contam só `status: "completed"`. Pendentes e canceladas aparecem só nos cards delas.
- Regra dos mesmos dias: todo percentual que envolve o mês atual compara os dias 1..`Date.current.day` dos dois meses (o outro mês limitado ao seu último dia). Valores exibidos são sempre do mês inteiro.
- Dinheiro: somar `sale_items.quantity * sale_items.unit_price` no SQL e converter com `.to_d.round(2)`. O SQLite devolve float: 3 × 4,10 + 0,35 vira `12.649999999999999`.
- Datas agregadas no SQLite (`MIN(sales.sale_date)`) voltam como `String`: converter com `to_date`.
- Percentuais com uma casa decimal, `nil` quando a base é zero, sempre via `Percentage` (Task 4). Fórmula: (mês da linha − mês de referência) ÷ referência.
- O dashboard não muda de comportamento.
- Textos fixos: "Relatórios", "Receita", "Vendas concluídas", "Unidades vendidas", "Ticket médio", "Pendentes", "Canceladas", "Não vinculado", sufixo "(sem cadastro)" para nomes em texto. O spec dizia "(importado)"; troquei porque vendas de quem excluiu a conta também caem nesse grupo.
- Commits em inglês, Conventional Commits como no histórico, sem `Co-Authored-By` e sem menção ao Claude.
- Ao fim de cada task: specs da task verdes e `bin/rubocop` limpo nos arquivos tocados. Ao fim do plano: `bundle exec rspec`, `bin/rubocop` e `bin/brakeman --no-pager` limpos.
- Todo arquivo de spec novo começa com `require "rails_helper"` (omitido nos trechos abaixo). Nos selects, passe `value:` antes de `selected:`; os testes procuram `<option value="..." selected`.
- Telas novas seguem o layout redesenhado da `main`:
  - contêiner `div(class: "container mx-auto px-0 py-4 sm:px-8 md:py-8")`
  - cabeçalho com `Components::PageHeader`
  - estado vazio com `Components::Listings::EmptyState`
  - dinheiro com `number_to_currency(valor)`, que no locale pt-BR já sai como "R$ 1.234,50"
- Linha de base em 2026-10-20, branch rebaseada sobre a `main` em `85c4eec`: `bundle exec rspec` → 562 examples, 0 failures.

## Review Focus

1. Organização sem nenhuma venda: a página abre, os cards ficam zerados com "Sem base", e ticket e participação não dividem por zero. Testes na Task 6 (`returns zeros and no percentages without sales`) e na Task 10 (`renders an organization without sales`).
2. Parâmetros inválidos ou de outra organização na URL (`month=2026-13`, `abc`, mês futuro, `product_id` de outra organização, `seller` malformado): a página cai nos padrões e nunca mostra dados de fora. Testes na Task 10 (`filters_spec` e `reports_spec`).
3. Mesmos dias nas bordas do calendário: hoje dia 31 contra um mês de 28 dias, e janeiro contra dezembro do ano anterior. Testes na Task 4.
4. Venda com dois itens do mesmo produto conta como uma venda, também com filtro de produto. Teste na Task 5.
5. Preços decimais (4,10 e 0,35): a receita do relatório é igual à do dashboard, sem resíduo de float. Teste na Task 6.

---

### Task 1: Venda ligada ao usuário vendedor

**Files:**
- Create: `db/migrate/20261020130000_add_seller_to_sales.rb`, `app/models/person_name.rb`
- Modify: `app/models/sale.rb`, `app/models/user.rb`, `app/models/organization.rb`
- Modify (gerados por `db:migrate`): `db/schema.rb`, anotações de `app/models/sale.rb` e `spec/factories/sales.rb`
- Test: `spec/models/person_name_spec.rb` (novo), `spec/models/sale_spec.rb`, `spec/models/user_spec.rb`, `spec/models/organization_spec.rb`

**Interfaces:**
- Produces:
  - `PersonName.normalize(value) -> String`: `I18n.transliterate(value.to_s).squish.upcase`
  - `Sale belongs_to :seller, class_name: "User", optional: true, inverse_of: :sold_sales`
  - `Sale::UNLINKED_SELLER_NAME = "Não vinculado"`
  - `Sale#seller_display_name -> String`: `seller.username`, senão `responsible_name` (sem espaços nas pontas, se não vazio), senão `"Não vinculado"`
  - `User has_many :sold_sales, class_name: "Sale", foreign_key: :seller_id, inverse_of: :seller`
  - `Organization#member_named(name) -> User | nil`

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/models/person_name_spec.rb
RSpec.describe PersonName do
  it "ignores case, accents and repeated spaces" do
    expect(described_class.normalize("  João   da Silva ")).to eq("JOAO DA SILVA")
  end

  it "returns an empty string for nil" do
    expect(described_class.normalize(nil)).to eq("")
  end
end

# spec/models/sale_spec.rb — em 'associations'
it { should belong_to(:seller).class_name("User").optional }

# spec/models/sale_spec.rb — novos blocos
describe "seller" do
  let(:organization) { create(:organization) }
  let(:seller) { create(:user, username: "maria") }

  it "accepts a member of the sale organization" do
    create(:membership, user: seller, organization: organization, role: "manager")
    expect(build(:sale, organization: organization, seller: seller)).to be_valid
  end

  it "rejects a user outside the sale organization" do
    sale = build(:sale, organization: organization, seller: seller)
    expect(sale).not_to be_valid
    expect(sale.errors[:seller]).to include("deve pertencer à mesma organização da venda")
  end

  it "keeps an old sale editable after the seller leaves the organization" do
    membership = create(:membership, user: seller, organization: organization, role: "manager")
    sale = create(:sale, organization: organization, seller: seller)
    membership.destroy!
    expect(sale.reload.update(notes: "Atualizada")).to be(true)
  end
end

describe "#seller_display_name" do
  it("uses the seller username") { expect(build(:sale, seller: build(:user, username: "maria")).seller_display_name).to eq("maria") }
  it("falls back to the stored name") { expect(build(:sale, responsible_name: "JOAO SILVA").seller_display_name).to eq("JOAO SILVA") }
  it("shows Não vinculado without seller or name") { expect(build(:sale, responsible_name: " ").seller_display_name).to eq("Não vinculado") }
end

# spec/models/user_spec.rb
it { should have_many(:sold_sales).class_name("Sale").with_foreign_key(:seller_id).inverse_of(:seller) }

describe "account deletion" do
  it "unlinks the user's sales in every organization and keeps the username as text" do
    user = create(:user, username: "maria")
    sales = create_list(:organization, 2).map do |organization|
      create(:membership, user: user, organization: organization, role: "manager")
      create(:sale, organization: organization, seller: user)
    end

    user.destroy!

    sales.each { |sale| expect(sale.reload).to have_attributes(seller_id: nil, responsible_name: "maria") }
  end

  it "keeps the seller link when the account cannot be deleted" do
    user = create(:user)
    organization = create(:organization)
    create(:membership, user: user, organization: organization, role: "owner")
    sale = create(:sale, organization: organization, seller: user)

    expect(user.destroy).to be(false)
    expect(sale.reload.seller_id).to eq(user.id)
  end
end

# spec/models/organization_spec.rb
describe "#member_named" do
  let(:organization) { create(:organization) }

  def member(username)
    create(:user, username: username).tap { |user| create(:membership, user: user, organization: organization, role: "manager") }
  end

  it "finds the member ignoring case, accents and extra spaces" do
    joao = member("João Silva")
    expect(organization.member_named("  JOAO   silva ")).to eq(joao)
  end

  it "ignores users outside the organization" do
    create(:user, username: "Pedro")
    expect(organization.member_named("PEDRO")).to be_nil
  end

  it "returns nil when more than one member matches" do
    member("ana")
    member("Ána")
    expect(organization.member_named("ANA")).to be_nil
  end

  it "returns nil for a blank name" do
    member("maria")
    expect(organization.member_named(" ")).to be_nil
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/models/person_name_spec.rb spec/models/sale_spec.rb spec/models/user_spec.rb spec/models/organization_spec.rb`
Expected: FAIL (`uninitialized constant PersonName`, `unknown attribute 'seller'`, `undefined method 'member_named'`).

- [ ] **Step 3: Add the migration and migrate**

`add_reference :sales, :seller, foreign_key: { to_table: :users }` (coluna nula, com índice). Rode `bin/rails db:migrate`. `git diff db/schema.rb` deve mostrar só a coluna `seller_id`, o índice e a FK; reverta qualquer outra diferença.

- [ ] **Step 4: Implement the models**

- `Sale`: validação `seller_must_belong_to_organization` só `if: :will_save_change_to_seller_id?`, erro em `:seller` com "deve pertencer à mesma organização da venda" (mesmo estilo de `client_must_belong_to_organization`).
- `User`: `sold_sales` sem `dependent:`, com um comentário curto dizendo que `before_destroy :keep_seller_name_on_sold_sales` cuida das vendas.
  - O callback faz `sold_sales.update_all(seller_id: nil, responsible_name: username, updated_at: Time.current)`. Sem ele, `destroy` falha na FK.
  - Declare o callback depois dos `has_many`. Quando a `Membership` impede a exclusão (único dono, regra da `main`), o `destroy` devolve `false` e a transação desfaz a atualização.
- `Organization#member_named`: compara `PersonName.normalize` do nome com o de cada usuário em `users`. Devolve o usuário só quando exatamente um corresponde, e `nil` para nome em branco.

- [ ] **Step 5: Run the tests to verify they pass**

Run: o comando do Step 2, depois `bin/rubocop app/models db/migrate spec/models`
Expected: PASS, sem ofensas.

- [ ] **Step 6: Commit**

```bash
git add db/migrate/20261020130000_add_seller_to_sales.rb db/schema.rb app/models spec/models spec/factories/sales.rb
git commit -m "feat: link sales to the seller user"
```

---

### Task 2: Telas de venda gravam o usuário logado

**Files:**
- Modify: `app/controllers/sales_controller.rb`, `app/models/sale.rb` (escopo `search`), `app/views/sales/form_component.rb`, `app/views/sales/show.rb`, `app/views/sales/index.rb`, `README.md`
- Test: `spec/requests/sales_spec.rb`

**Interfaces:**
- Consumes: `Sale#seller`, `Sale#seller_display_name` (Task 1)

- [ ] **Step 1: Write the failing tests**

Substitua o teste `"persists the responsible name"` e acrescente:

```ruby
# POST /sales, contexto "with valid parameters"
it "records the signed-in user as the seller and ignores seller fields from the form" do
  other_user = create(:user)
  post sales_path, params: { sale: valid_attributes.merge(seller_id: other_user.id, responsible_name: "Lucas") }
  expect(Sale.last).to have_attributes(seller_id: user.id, responsible_name: nil)
end

# PATCH /sales/:id, contexto "with valid parameters"
it "keeps the original seller" do
  seller = create(:user)
  create(:membership, user: seller, organization: organization, role: "manager")
  sale.update!(seller: seller, responsible_name: "VENDEDOR ORIGINAL")

  patch sale_path(sale), params: { sale: { status: "completed", seller_id: user.id, responsible_name: "Outro" } }

  expect(sale.reload).to have_attributes(seller_id: seller.id, responsible_name: "VENDEDOR ORIGINAL")
end

# GET /sales/new
it "shows the signed-in user as the read-only responsible" do
  get new_sale_path
  expect(Capybara.string(response.body).find("#sale_seller").text).to eq(user.username)
  expect(response.body).not_to include('name="sale[responsible_name]"', 'name="sale[seller_id]"')
end

# GET /sales
it "shows each sale's seller" do
  sale.update!(seller: user)
  create(:sale, organization: organization, client: client)
  get sales_path
  results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
  expect(results_text).to include(user.username, "Não vinculado")
end

# GET /sales/:id
it "displays the seller username" do
  sale.update!(seller: user)
  get sale_path(sale)
  expect(Capybara.string(response.body).find("dl").text).to include("Responsável", user.username)
end

# describe "sales filters"
it "searches by seller username" do
  seller = create(:user, username: "joana_feira")
  create(:membership, user: seller, organization: organization, role: "manager")
  completed_sale.update!(seller: seller)

  get sales_path, params: { q: "joana" }

  results_text = Capybara.string(response.body).find("turbo-frame#sales_results").text
  expect(results_text).to include("Cliente Concluido")
  expect(results_text).not_to include("Cliente Pendente")
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/requests/sales_spec.rb`
Expected: FAIL nos testes novos.

- [ ] **Step 3: Implement**

- `new`: `build(sale_date: Date.current, seller: Current.user)`.
- `create`: monta com `sale_params` e depois atribui `@sale.seller = Current.user`.
- `sale_params`: tirar `:responsible_name`. `update` não mexe em vendedor.
- `index`: acrescentar `:seller` ao `includes` atual.
- `Sale.search`: incluir `left_joins(:seller)` e `OR users.username LIKE :term`. A busca "Cliente ou responsável" passa a achar também o vendedor vinculado.
- Formulário: bloco somente leitura "Responsável" com `p(id: "sale_seller") { @sale.seller_display_name }`, como texto e sem input, depois da linha Data/Status e antes de "Observações".
- `show`: o item "Responsável" do `Components::DetailList` aparece sempre, com `seller_display_name` (tira o `if` atual).
- `index`: a célula "Responsável" usa `seller_display_name`.
- README, em "Funcionalidades Implementadas": "Responsável da venda: o usuário logado que cria a venda fica registrado e não muda na edição. Se ele excluir a conta, o nome continua na venda como texto."

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bundle exec rspec spec/requests/sales_spec.rb && bin/rubocop app/controllers/sales_controller.rb app/views/sales`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/sales_controller.rb app/models/sale.rb app/views/sales README.md spec/requests/sales_spec.rb
git commit -m "feat: record the signed-in user as the sale seller"
```

---

### Task 3: Importação e vendas antigas vinculadas pelo nome

**Files:**
- Modify: `app/services/imports/sales_spreadsheet_importer.rb`, `app/models/sale.rb`, `README.md`
- Create: `lib/tasks/sales.rake`
- Test: `spec/services/imports/sales_spreadsheet_importer_spec.rb`, `spec/models/sale_spec.rb`

**Interfaces:**
- Consumes: `Organization#member_named` (Task 1)
- Produces: `Sale.link_unlinked_sellers -> Integer` (quantas vendas vinculou)

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/services/imports/sales_spreadsheet_importer_spec.rb
def row(responsible)
  [ "QUINTA", "02/10/2026", "AGROVALE", "ALFACE", 15, "60,00", responsible, "PG", nil ]
end

it "links the sale to the member whose username matches RESPONSAVEL" do
  seller = create(:user, username: "Lucas")
  create(:membership, user: seller, organization: organization, role: "manager")
  importer_for([ row("LUCAS") ]).call
  expect(organization.sales.sole).to have_attributes(seller_id: seller.id, responsible_name: "LUCAS")
end

it "keeps only the name when RESPONSAVEL matches no member" do
  importer_for([ row("JOAO") ]).call
  expect(organization.sales.sole).to have_attributes(seller_id: nil, responsible_name: "JOAO")
end

it "keeps only the name when RESPONSAVEL matches more than one member" do
  %w[ana Ána].each { |username| create(:membership, user: create(:user, username: username), organization: organization, role: "manager") }
  importer_for([ row("ANA") ]).call
  expect(organization.sales.sole).to have_attributes(seller_id: nil, responsible_name: "ANA")
end

# spec/models/sale_spec.rb
describe ".link_unlinked_sellers" do
  it "links unlinked sales whose name matches one member of the sale organization" do
    organization = create(:organization)
    maria = create(:user, username: "maria")
    create(:membership, user: maria, organization: organization, role: "manager")
    matching = create(:sale, organization: organization, responsible_name: "MARIA")
    unmatched = create(:sale, organization: organization, responsible_name: "PEDRO")
    other_organization_sale = create(:sale, responsible_name: "MARIA")

    expect(Sale.link_unlinked_sellers).to eq(1)
    expect(matching.reload.seller).to eq(maria)
    expect(unmatched.reload.seller).to be_nil
    expect(other_organization_sale.reload.seller).to be_nil
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/services/imports/sales_spreadsheet_importer_spec.rb spec/models/sale_spec.rb`
Expected: FAIL nos testes novos.

- [ ] **Step 3: Implement**

- Importador, em `import_sale`: `seller: organization.member_named(first_row[:responsible_name])`. `responsible_name` continua gravado.
- `Sale.link_unlinked_sellers`: percorre as vendas com `seller_id` nulo e `responsible_name` preenchido (`includes(:organization)`, `find_each`), chama `sale.organization.member_named` e grava com `update_column(:seller_id, ...)`, sem callbacks e sem mudar `updated_at`.
- `lib/tasks/sales.rake`: task `sales:link_sellers` com `desc "Vincula vendas sem vendedor ao membro cujo username corresponde ao responsável"`, que imprime `"#{Sale.link_unlinked_sellers} venda(s) vinculada(s)."`.
- README, em "Importação de Vendas e Retenção de Dados":
  - "A coluna `RESPONSAVEL` vincula a venda ao membro da organização cujo `username` corresponde ao nome, ignorando maiúsculas, acentos e espaços extras. Sem correspondência única, a venda guarda só o nome em texto."
  - "Vendas registradas antes dessa regra podem ser vinculadas com `bin/rails sales:link_sellers`."

- [ ] **Step 4: Run the tests to verify they pass**

Run: o comando do Step 2, depois `bin/rubocop app/services app/models lib/tasks`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/services/imports/sales_spreadsheet_importer.rb app/models/sale.rb lib/tasks/sales.rake README.md spec
git commit -m "feat: link imported sales to sellers by username"
```

---

### Task 4: Percentuais e período do relatório

**Files:**
- Create: `app/queries/percentage.rb`, `app/queries/reports/period.rb`
- Modify: `app/queries/dashboard/overview_query.rb` (o `percentage_change` privado passa a chamar `Percentage.change`)
- Test: `spec/queries/percentage_spec.rb`, `spec/queries/reports/period_spec.rb`; `spec/queries/dashboard/overview_query_spec.rb` continua verde

**Interfaces:**
- Produces:
  - `Percentage.change(current, previous) -> BigDecimal | nil`: `((current.to_d − previous) ÷ previous × 100).round(1)`; `nil` se `previous` é `nil` ou zero. O `to_d` evita divisão inteira.
  - `Percentage.share(part, whole) -> BigDecimal | nil`: `(part.to_d ÷ whole × 100).round(1)`; `nil` se `whole` é zero
  - `Reports::Period.new(month:, comparison:, today: Date.current)`, com:
    - `#month -> Date`: dia 1; mês futuro vira o mês atual
    - `#comparison -> :previous | :current`: `"current"`/`:current` só vale se o mês escolhido não for o atual; qualquer outro valor vira `:previous`
    - `#today`, `#current_month -> Date`, `#current_month? -> Boolean`, `#base_month -> Date`
    - `#range -> Range<Date>`: o mês inteiro escolhido
    - `#base_windows -> [Range<Date>, Range<Date>]`: escolhido e base
    - `#current_windows -> [Range<Date>, Range<Date>] | nil`: escolhido e mês atual; `nil` quando `current_month?` ou quando `comparison == :current`
    - `#year_months -> Array<Date>`: os 12 meses do ano de `month`
    - `Reports::Period.windows(month_a, month_b, today:) -> [Range<Date>, Range<Date>]`

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/queries/percentage_spec.rb
RSpec.describe Percentage do
  it { expect(described_class.change(150, 100)).to eq(50.0) }
  it { expect(described_class.change(1, 3)).to eq(-66.7) }
  it { expect(described_class.change(0, 100)).to eq(-100.0) }
  it { expect(described_class.change(10, 0)).to be_nil }
  it { expect(described_class.change(10, nil)).to be_nil }
  it { expect(described_class.share(1, 3)).to eq(33.3) }
  it { expect(described_class.share(5, 0)).to be_nil }
end

# spec/queries/reports/period_spec.rb
RSpec.describe Reports::Period do
  let(:today) { Date.new(2026, 10, 20) }
  def d(month, day) = Date.new(2026, month, day)

  it "compares a past month with the previous one in full and with the current month by the same days" do
    period = described_class.new(month: d(8, 15), comparison: "previous", today: today)
    expect(period.month).to eq(d(8, 1))
    expect(period.base_month).to eq(d(7, 1))
    expect(period.range).to eq(d(8, 1)..d(8, 31))
    expect(period.base_windows).to eq([ d(8, 1)..d(8, 31), d(7, 1)..d(7, 31) ])
    expect(period.current_windows).to eq([ d(8, 1)..d(8, 20), d(10, 1)..d(10, 20) ])
  end

  it "uses the same days when the base is the current month" do
    period = described_class.new(month: d(8, 1), comparison: "current", today: today)
    expect(period.comparison).to eq(:current)
    expect(period.base_windows).to eq([ d(8, 1)..d(8, 20), d(10, 1)..d(10, 20) ])
    expect(period.current_windows).to be_nil
  end

  it "compares the current month with the same days of the previous month" do
    period = described_class.new(month: d(10, 1), comparison: "previous", today: today)
    expect(period.base_windows).to eq([ d(10, 1)..d(10, 20), d(9, 1)..d(9, 20) ])
    expect(period.current_windows).to be_nil
  end

  it "treats 'current' as previous when the current month is selected" do
    period = described_class.new(month: d(10, 1), comparison: "current", today: today)
    expect(period.comparison).to eq(:previous)
    expect(period.base_month).to eq(d(9, 1))
  end

  it "clamps a future month to the current month" do
    expect(described_class.new(month: Date.new(2027, 1, 1), comparison: "previous", today: today).month).to eq(d(10, 1))
  end

  it "limits a shorter month to its last day on the 31st" do
    period = described_class.new(month: Date.new(2027, 3, 1), comparison: "previous", today: Date.new(2027, 3, 31))
    expect(period.base_windows).to eq([ Date.new(2027, 3, 1)..Date.new(2027, 3, 31), Date.new(2027, 2, 1)..Date.new(2027, 2, 28) ])
  end

  it "compares January with December of the previous year" do
    period = described_class.new(month: d(1, 1), comparison: "previous", today: today)
    expect(period.base_windows).to eq([ d(1, 1)..d(1, 31), Date.new(2025, 12, 1)..Date.new(2025, 12, 31) ])
  end

  it "lists the twelve months of the selected year" do
    expect(described_class.new(month: d(8, 1), comparison: "previous", today: today).year_months).to eq((1..12).map { |m| d(m, 1) })
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/queries/percentage_spec.rb spec/queries/reports/period_spec.rb`
Expected: FAIL (`uninitialized constant Percentage`).

- [ ] **Step 3: Implement**

`Percentage` como módulo com dois métodos de classe. Em `Reports::Period.windows`, o corte vale para os dois meses quando qualquer um deles é o mês atual:

```ruby
def self.windows(month_a, month_b, today:)
  current = today.beginning_of_month
  return [ month_a.all_month, month_b.all_month ] unless [ month_a, month_b ].include?(current)

  [ month_a, month_b ].map { |month| month..[ month + (today.day - 1), month.end_of_month ].min }
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bundle exec rspec spec/queries && bin/rubocop app/queries spec/queries`
Expected: PASS, incluindo `overview_query_spec`.

- [ ] **Step 5: Commit**

```bash
git add app/queries spec/queries
git commit -m "feat: add report period with same-days comparison"
```

---

### Task 5: Escopo filtrado do relatório

**Files:**
- Create: `app/queries/reports/seller_key.rb`, `app/queries/reports/scope.rb`, `spec/support/report_sales_helper.rb`
- Test: `spec/queries/reports/seller_key_spec.rb`, `spec/queries/reports/scope_spec.rb`

**Interfaces:**
- Consumes: `PersonName.normalize` (Task 1)
- Produces:
  - `Reports::SellerKey::UNLINKED = "none"`
  - `Reports::SellerKey.for(seller_id:, responsible_name:) -> String`: `"user:<id>"`, `"name:<PersonName.normalize(nome)>"` ou `"none"` (nome em branco)
  - `Reports::SellerKey.valid?(key) -> Boolean`: aceita `/\Auser:\d+\z/`, `/\Aname:.+\z/` e `"none"`
  - `Reports::SellerKey.sales_condition(key, organization:) -> ActiveRecord::Relation<Sale>`, para usar com `merge`:
    - `user:<id>`: `seller_id`
    - `name:<N>`: `seller_id: nil` e `responsible_name` em todas as grafias das vendas sem vínculo da organização que normalizam para `N`
    - `none`: `seller_id: nil` e `TRIM(COALESCE(sales.responsible_name, '')) = ''`
  - `Reports::Scope.new(organization:, product: nil, seller_key: nil)`, com leitores `#organization`, `#product`, `#seller_key`
  - `Reports::Scope#items(range, status: "completed") -> ActiveRecord::Relation<SaleItem>`: `SaleItem.joins(:sale)` filtrado por organização, `sales.status` (string ou array), `sales.sale_date` em `range`, produto e vendedor
  - `Reports::Scope#totals(range) -> Hash{String => Reports::Scope::Totals}`:
    - chaves `"completed"`, `"pending"` e `"cancelled"` sempre presentes, com zeros quando não há vendas
    - uma consulta agrupada por `sales.status`, memoizada por `range`
  - `Reports::Scope::Totals = Data.define(:revenue, :sales_count, :units)`, com `.zero` e `#ticket -> BigDecimal | nil` (`(revenue.to_d / sales_count).round(2)`, `nil` sem vendas). `sales_count` é `COUNT(DISTINCT sale_items.sale_id)`.
  - Helper de teste `create_report_sale(organization:, date:, items:, status: "completed", seller: nil, responsible_name: nil)`, com `items` no formato `[[product, quantity, unit_price], ...]`

- [ ] **Step 1: Write the helper and the failing tests**

```ruby
# spec/support/report_sales_helper.rb
module ReportSalesHelper
  def create_report_sale(organization:, date:, items:, status: "completed", seller: nil, responsible_name: nil)
    client = organization.clients.first || create(:client, organization: organization)
    create(:sale, organization: organization, client: client, status: status, sale_date: date,
      seller: seller, responsible_name: responsible_name,
      sale_items_attributes: items.map { |product, quantity, unit_price|
        { product_id: product.id, quantity: quantity, unit_price: unit_price, custom_price: true }
      })
  end
end

RSpec.configure { |config| config.include ReportSalesHelper }

# spec/queries/reports/seller_key_spec.rb
RSpec.describe Reports::SellerKey do
  let(:organization) { create(:organization) }
  let(:product) { create(:product, organization: organization) }

  it "builds keys for users, text names and unlinked sales" do
    expect(described_class.for(seller_id: 7, responsible_name: "x")).to eq("user:7")
    expect(described_class.for(seller_id: nil, responsible_name: " joão silva ")).to eq("name:JOAO SILVA")
    expect(described_class.for(seller_id: nil, responsible_name: " ")).to eq("none")
  end

  it "validates key format" do
    expect(%w[user:7 name:JOAO none].map { |key| described_class.valid?(key) }).to all(be(true))
    expect([ "user:abc", "x", "", nil ].map { |key| described_class.valid?(key) }).to all(be(false))
  end

  it "filters sales by text name across spellings, excluding linked sales" do
    linked_user = create(:user, username: "JOAO SILVA")
    create(:membership, user: linked_user, organization: organization, role: "manager")
    accented = create_report_sale(organization: organization, date: Date.new(2026, 8, 1), items: [ [ product, 1, 1 ] ], responsible_name: "João Silva")
    plain = create_report_sale(organization: organization, date: Date.new(2026, 8, 2), items: [ [ product, 1, 1 ] ], responsible_name: "JOAO SILVA")
    create_report_sale(organization: organization, date: Date.new(2026, 8, 3), items: [ [ product, 1, 1 ] ], seller: linked_user, responsible_name: "JOAO SILVA")
    unlinked = create_report_sale(organization: organization, date: Date.new(2026, 8, 4), items: [ [ product, 1, 1 ] ])

    by_name = organization.sales.merge(described_class.sales_condition("name:JOAO SILVA", organization: organization))
    by_none = organization.sales.merge(described_class.sales_condition("none", organization: organization))

    expect(by_name).to contain_exactly(accented, plain)
    expect(by_none).to contain_exactly(unlinked)
  end
end

# spec/queries/reports/scope_spec.rb
RSpec.describe Reports::Scope do
  let(:organization) { create(:organization) }
  let(:a) { create(:product, organization: organization) }
  let(:b) { create(:product, organization: organization) }
  let(:maria) { create(:user).tap { |user| create(:membership, user: user, organization: organization, role: "manager") } }
  let(:august) { Date.new(2026, 8, 1).all_month }

  before do
    create_report_sale(organization: organization, date: Date.new(2026, 8, 5), seller: maria, items: [ [ a, 2, 10 ], [ b, 1, 5 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 10), items: [ [ a, 1, 10 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 12), status: "pending", items: [ [ b, 4, 5 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 15), status: "cancelled", items: [ [ a, 1, 10 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 7, 30), items: [ [ a, 9, 10 ] ])
    other = create(:organization)
    create_report_sale(organization: other, date: Date.new(2026, 8, 5), items: [ [ create(:product, organization: other), 5, 100 ] ])
  end

  def totals(scope, status) = scope.totals(august).fetch(status).to_h

  it "totals each status in the range for the organization only" do
    scope = described_class.new(organization: organization)
    expect(totals(scope, "completed")).to eq(revenue: 35, sales_count: 2, units: 4)
    expect(totals(scope, "pending")).to eq(revenue: 20, sales_count: 1, units: 4)
    expect(totals(scope, "cancelled")).to eq(revenue: 10, sales_count: 1, units: 1)
  end

  it "filters by product" do
    scope = described_class.new(organization: organization, product: a)
    expect(totals(scope, "completed")).to eq(revenue: 30, sales_count: 2, units: 3)
    expect(totals(scope, "pending")).to eq(revenue: 0, sales_count: 0, units: 0)
  end

  it "filters by seller key" do
    expect(totals(described_class.new(organization: organization, seller_key: "user:#{maria.id}"), "completed")).to eq(revenue: 25, sales_count: 1, units: 3)
    expect(totals(described_class.new(organization: organization, seller_key: "none"), "completed")).to eq(revenue: 10, sales_count: 1, units: 1)
  end

  it "counts a sale once even with two items of the same product" do
    create_report_sale(organization: organization, date: Date.new(2026, 8, 20), items: [ [ a, 1, 10 ], [ a, 2, 10 ] ])
    expect(totals(described_class.new(organization: organization, product: a), "completed")).to eq(revenue: 60, sales_count: 3, units: 6)
  end

  it "computes the ticket" do
    expect(Reports::Scope::Totals.new(revenue: 35, sales_count: 2, units: 4).ticket).to eq(17.5)
    expect(Reports::Scope::Totals.zero.ticket).to be_nil
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/queries/reports/seller_key_spec.rb spec/queries/reports/scope_spec.rb`
Expected: FAIL (`uninitialized constant Reports::SellerKey`).

- [ ] **Step 3: Implement `Reports::SellerKey` and `Reports::Scope` per the interfaces**

- [ ] **Step 4: Run the tests to verify they pass**

Run: o comando do Step 2, depois `bin/rubocop app/queries/reports spec`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/queries/reports spec/support/report_sales_helper.rb spec/queries/reports
git commit -m "feat: add report scope with product and seller filters"
```

---

### Task 6: Resumo do mês (cards)

**Files:**
- Create: `app/queries/reports/summary.rb`
- Test: `spec/queries/reports/summary_spec.rb`

**Interfaces:**
- Consumes: `Reports::Scope#totals`, `Reports::Period#range/#base_windows/#current_windows`, `Percentage`
- Produces:
  - `Reports::Summary.new(scope:, period:)`
  - `#revenue`, `#sales_count`, `#units`, `#ticket -> Reports::Summary::Metric`, onde `Metric = Data.define(:value, :change, :current_change)`. Regras:
    - `value` vem de `totals(period.range)["completed"]`; no ticket, de `Totals#ticket`
    - `change` compara o mesmo atributo entre as duas janelas de `base_windows`
    - `current_change` faz o mesmo com `current_windows`, e é `nil` quando elas são `nil`
  - `#pending`, `#cancelled -> Reports::Summary::StatusMetric`, onde `StatusMetric = Data.define(:count, :value, :share, :change, :current_change)`. Regras:
    - `count` e `value` são `sales_count` e `revenue` do status no mês inteiro
    - `share = Percentage.share(count, soma das contagens dos três status no mês)`
    - `change` e `current_change` são calculados sobre `count`

- [ ] **Step 1: Write the failing tests**

```ruby
RSpec.describe Reports::Summary do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }
  let(:a) { create(:product, organization: organization) }
  let(:b) { create(:product, organization: organization) }

  def summary(month:, comparison: "previous", product: nil)
    period = Reports::Period.new(month: month, comparison: comparison, today: today)
    described_class.new(scope: Reports::Scope.new(organization: organization, product: product), period: period)
  end

  def sale(date, items, status: "completed") = create_report_sale(organization: organization, date: date, status: status, items: items)

  context "with a year of sales" do
    before do
      sale(Date.new(2026, 7, 5), [ [ a, 2, 10 ] ])
      sale(Date.new(2026, 7, 25), [ [ a, 1, 10 ] ])
      sale(Date.new(2026, 7, 3), [ [ b, 1, 5 ] ], status: "pending")
      sale(Date.new(2026, 8, 5), [ [ a, 3, 10 ] ])
      sale(Date.new(2026, 8, 18), [ [ b, 2, 5 ] ])
      sale(Date.new(2026, 8, 28), [ [ a, 1, 10 ] ])
      sale(Date.new(2026, 8, 3), [ [ b, 1, 5 ] ], status: "pending")
      sale(Date.new(2026, 8, 25), [ [ b, 2, 5 ] ], status: "pending")
      sale(Date.new(2026, 8, 10), [ [ a, 1, 10 ] ], status: "cancelled")
      sale(Date.new(2026, 9, 10), [ [ a, 2, 10 ] ])
      sale(Date.new(2026, 9, 25), [ [ b, 2, 5 ] ])
      sale(Date.new(2026, 10, 2), [ [ a, 2, 10 ] ])
      sale(Date.new(2026, 10, 19), [ [ b, 1, 5 ] ])
      sale(Date.new(2026, 10, 25), [ [ a, 1, 10 ] ])
    end

    it "shows August against July and against the same days of October" do
      result = summary(month: Date.new(2026, 8, 1))
      expect(result.revenue.to_h).to eq(value: 50, change: 66.7, current_change: 60.0)
      expect(result.sales_count.to_h).to eq(value: 3, change: 50.0, current_change: 0.0)
      expect(result.units.to_h).to eq(value: 6, change: 100.0, current_change: 66.7)
      expect(result.ticket.to_h).to eq(value: 16.67, change: 11.1, current_change: 60.0)
      expect(result.pending.to_h).to eq(count: 2, value: 15, share: 33.3, change: 100.0, current_change: nil)
      expect(result.cancelled.to_h).to eq(count: 1, value: 10, share: 16.7, change: nil, current_change: nil)
    end

    it "uses the same days when comparing with the current month" do
      result = summary(month: Date.new(2026, 8, 1), comparison: "current")
      expect(result.revenue.change).to eq(60.0)
      expect(result.revenue.current_change).to be_nil
    end

    it "shows the whole current month but compares only up to today" do
      result = summary(month: Date.new(2026, 10, 1))
      expect(result.revenue.value).to eq(35)
      expect(result.revenue.change).to eq(25.0)
    end

    it "applies the product filter to every metric" do
      result = summary(month: Date.new(2026, 8, 1), product: b)
      expect(result.revenue.to_h).to include(value: 10, change: nil)
      expect(result.sales_count.value).to eq(1)
      expect(result.units.value).to eq(2)
    end
  end

  it "matches the dashboard for the current month with decimal prices" do
    sale(Date.new(2026, 10, 5), [ [ a, 3, 4.10 ], [ b, 1, 0.35 ] ])
    sale(Date.new(2026, 10, 6), [ [ a, 1, 4.10 ] ], status: "pending")
    sale(Date.new(2026, 10, 7), [ [ b, 2, 0.35 ] ], status: "cancelled")
    result = summary(month: Date.new(2026, 10, 1))
    dashboard = Dashboard::OverviewQuery.new(organization: organization, today: today)

    expect(result.revenue.value).to eq(BigDecimal("12.65"))
    expect(result.revenue.value).to eq(dashboard.revenue)
    expect(result.sales_count.value + result.pending.count + result.cancelled.count).to eq(dashboard.sales_count)
  end

  it "returns zeros and no percentages without sales" do
    result = summary(month: Date.new(2026, 10, 1))
    expect(result.revenue.to_h).to eq(value: 0, change: nil, current_change: nil)
    expect(result.ticket.value).to be_nil
    expect(result.pending.share).to be_nil
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/queries/reports/summary_spec.rb`
Expected: FAIL (`uninitialized constant Reports::Summary`).

- [ ] **Step 3: Implement `Reports::Summary` per the interfaces**

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bundle exec rspec spec/queries/reports/summary_spec.rb && bin/rubocop app/queries/reports`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/queries/reports/summary.rb spec/queries/reports/summary_spec.rb
git commit -m "feat: add monthly report summary metrics"
```

---

### Task 7: Série do ano

**Files:**
- Create: `app/queries/reports/year_series.rb`
- Test: `spec/queries/reports/year_series_spec.rb`

**Interfaces:**
- Consumes: `Reports::Scope#items`, `Reports::Period#year_months/#today/#current_month`, `Reports::Period.windows`, `Percentage.change`
- Produces:
  - `Reports::YearSeries.new(scope:, period:)`
  - `#points -> Array<Reports::YearSeries::Point>`, onde `Point = Data.define(:month, :revenue, :change, :state)` e `state` é `:past`, `:current` ou `:future`

Regras:

- Receita de cada mês = receita concluída do mês inteiro. Sai de uma consulta agrupada por `strftime('%Y-%m', sales.sale_date)`, de 1º de dezembro do ano anterior até 31 de dezembro do ano escolhido.
- Mês futuro: `revenue: nil` e `change: nil`.
- `change` compara cada mês com o anterior, ambos inteiros. A exceção é o mês atual, que usa `Period.windows(mês, mês anterior, today:)`.

- [ ] **Step 1: Write the failing tests**

```ruby
RSpec.describe Reports::YearSeries do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }
  let(:a) { create(:product, organization: organization) }
  let(:b) { create(:product, organization: organization) }

  def points(month:, product: nil)
    period = Reports::Period.new(month: month, comparison: "previous", today: today)
    described_class.new(scope: Reports::Scope.new(organization: organization, product: product), period: period).points
  end

  before do
    [
      [ Date.new(2025, 12, 15), [ [ a, 1, 10 ] ], "completed" ],
      [ Date.new(2026, 1, 10), [ [ a, 2, 10 ] ], "completed" ],
      [ Date.new(2026, 1, 12), [ [ a, 10, 10 ] ], "pending" ],
      [ Date.new(2026, 3, 5), [ [ b, 3, 5 ] ], "completed" ],
      [ Date.new(2026, 9, 10), [ [ a, 2, 10 ] ], "completed" ],
      [ Date.new(2026, 9, 25), [ [ b, 2, 5 ] ], "completed" ],
      [ Date.new(2026, 10, 2), [ [ a, 2, 10 ], [ b, 1, 5 ] ], "completed" ],
      [ Date.new(2026, 10, 25), [ [ a, 1, 10 ] ], "completed" ]
    ].each { |date, items, status| create_report_sale(organization: organization, date: date, items: items, status: status) }
  end

  it "returns completed revenue, change and state for each month of the selected year" do
    result = points(month: Date.new(2026, 8, 1))
    expect(result.map(&:month)).to eq((1..12).map { |m| Date.new(2026, m, 1) })
    expect(result.map(&:revenue)).to eq([ 20, 0, 15, 0, 0, 0, 0, 0, 30, 35, nil, nil ])
    expect(result.map(&:change)).to eq([ 100.0, -100.0, nil, -100.0, nil, nil, nil, nil, nil, 25.0, nil, nil ])
    expect(result.map(&:state)).to eq([ :past ] * 9 + [ :current, :future, :future ])
  end

  it "applies the product filter" do
    result = points(month: Date.new(2026, 8, 1), product: b)
    expect(result[8].revenue).to eq(10)
    expect(result[9].revenue).to eq(5)
  end

  it "marks every month of a past year as past" do
    result = points(month: Date.new(2025, 3, 1))
    expect(result.map(&:state).uniq).to eq([ :past ])
    expect(result.last.revenue).to eq(10)
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/queries/reports/year_series_spec.rb`
Expected: FAIL (`uninitialized constant Reports::YearSeries`).

- [ ] **Step 3: Implement `Reports::YearSeries` per the rules**

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bundle exec rspec spec/queries/reports/year_series_spec.rb && bin/rubocop app/queries/reports`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/queries/reports/year_series.rb spec/queries/reports/year_series_spec.rb
git commit -m "feat: add yearly revenue series for reports"
```

---

### Task 8: Produtos

**Files:**
- Create: `app/queries/reports/product_breakdown.rb`
- Test: `spec/queries/reports/product_breakdown_spec.rb`

**Interfaces:**
- Consumes: `Reports::Scope#items/#organization/#product`, `Reports::Period#range/#base_windows`, `Percentage`
- Produces:
  - `Reports::ProductBreakdown.new(scope:, period:)`
  - `#rows -> Array<Reports::ProductBreakdown::Row>`, onde `Row = Data.define(:product, :quantity, :revenue, :share, :change, :first_sold_in_month)`

Regras:

- **Quais produtos entram:** os da organização com pelo menos um item em venda concluída, contados no nível da organização, sem o filtro de vendedor. Com filtro de produto, só ele (se já vendeu alguma vez).
- **`quantity` e `revenue`:** do mês inteiro, com os filtros aplicados.
- **`share`:** `Percentage.share(revenue, soma da receita das linhas)`.
- **`change`:** `Percentage.change` entre a quantidade na janela do mês escolhido e a quantidade na janela da base (as duas de `base_windows`).
- **`first_sold_in_month`:** verdadeiro quando a primeira venda concluída do produto na organização cai em `period.range`, a quantidade na janela escolhida é maior que zero e a da base é zero.
- **Ordem:** `quantity` decrescente, depois `product.name`.

- [ ] **Step 1: Write the failing tests**

```ruby
RSpec.describe Reports::ProductBreakdown do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }
  let(:maria) { create(:user).tap { |user| create(:membership, user: user, organization: organization, role: "manager") } }
  let(:products) do
    %w[Alface Rúcula Couve Cheiro\ Verde Pepino Tomate].index_with { |name| create(:product, organization: organization, name: name) }
  end

  def rows(product: nil, seller_key: nil)
    period = Reports::Period.new(month: Date.new(2026, 8, 1), comparison: "previous", today: today)
    scope = Reports::Scope.new(organization: organization, product: product, seller_key: seller_key)
    described_class.new(scope: scope, period: period).rows
  end

  before do
    p = products
    create_report_sale(organization: organization, date: Date.new(2026, 3, 10), items: [ [ p["Pepino"], 2, 5 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 5, 10), items: [ [ p["Couve"], 1, 4 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 7, 10), items: [ [ p["Alface"], 4, 2 ], [ p["Rúcula"], 5, 3 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 5), items: [ [ p["Alface"], 6, 2 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 10), seller: maria, items: [ [ p["Cheiro Verde"], 3, 1 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 12), items: [ [ p["Couve"], 1, 4 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 15), status: "pending", items: [ [ p["Tomate"], 1, 3 ] ])
  end

  it "lists every product ever sold, including the ones that stopped selling" do
    result = rows
    expect(result.map { |row| row.product.name }).to eq([ "Alface", "Cheiro Verde", "Couve", "Pepino", "Rúcula" ])
    expect(result.map(&:quantity)).to eq([ 6, 3, 1, 0, 0 ])
    expect(result.map(&:revenue)).to eq([ 12, 3, 4, 0, 0 ])
    expect(result.map(&:share)).to eq([ 63.2, 15.8, 21.1, 0.0, 0.0 ])
    expect(result.map(&:change)).to eq([ 50.0, nil, nil, nil, -100.0 ])
    expect(result.map(&:first_sold_in_month)).to eq([ false, true, false, false, false ])
  end

  it "keeps the product list with a seller filter and shows zeros" do
    result = rows(seller_key: "user:#{maria.id}")
    expect(result.map { |row| row.product.name }).to eq([ "Cheiro Verde", "Alface", "Couve", "Pepino", "Rúcula" ])
    expect(result.map(&:quantity)).to eq([ 3, 0, 0, 0, 0 ])
    expect(result.first.first_sold_in_month).to be(true)
  end

  it "shows only the filtered product" do
    expect(rows(product: products["Alface"]).map { |row| [ row.product.name, row.quantity ] }).to eq([ [ "Alface", 6 ] ])
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/queries/reports/product_breakdown_spec.rb`
Expected: FAIL (`uninitialized constant Reports::ProductBreakdown`).

- [ ] **Step 3: Implement `Reports::ProductBreakdown` per the rules** (a data mínima vem como `String` do SQLite; converter com `to_date`)

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bundle exec rspec spec/queries/reports/product_breakdown_spec.rb && bin/rubocop app/queries/reports`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/queries/reports/product_breakdown.rb spec/queries/reports/product_breakdown_spec.rb
git commit -m "feat: add product breakdown for reports"
```

---

### Task 9: Vendedores

**Files:**
- Modify: `app/queries/reports/seller_key.rb`
- Create: `app/queries/reports/seller_breakdown.rb`
- Test: `spec/queries/reports/seller_key_spec.rb`, `spec/queries/reports/seller_breakdown_spec.rb`

**Interfaces:**
- Consumes: `Reports::SellerKey.for`, `Reports::Scope#items`, `Reports::Period#range/#base_windows`, `Percentage`
- Produces:
  - `Reports::SellerKey.name_labels(organization) -> Hash{String => String}`: para cada chave `"name:N"`, a grafia em ordem alfabética mais baixa entre as vendas sem vínculo da organização (vale para a tabela e para o filtro)
  - `Reports::SellerKey.options(organization) -> Array<[String, String]>`, nesta ordem:
    1. usuários membros ou que já venderam na organização, por `username`, como `[username, "user:<id>"]`
    2. nomes em texto, por rótulo, como `["<rótulo> (sem cadastro)", "name:N"]`
    3. `["Não vinculado", "none"]`
  - `Reports::SellerBreakdown.new(scope:, period:)`
  - `#rows -> Array<Reports::SellerBreakdown::Row>`, onde `Row = Data.define(:key, :name, :kind, :sales_count, :revenue, :share, :change)` e `kind` é `:user`, `:name` ou `:none`

Regras:

- **Agrupamento:** itens concluídos do mês inteiro agrupados por `sales.seller_id` e `sales.responsible_name` (`COUNT(DISTINCT sale_id)` e receita). Cada grupo vira uma chave com `SellerKey.for`, e grupos com a mesma chave se somam.
- **`name`:** `username` (buscado por `User.where(id:)`, para incluir quem saiu da organização); senão o rótulo de `name_labels`; senão "Não vinculado".
- **`share`:** sobre a receita total das linhas.
- **`change`:** receita da chave na janela escolhida contra a janela da base.
- **Ordem e corte:** receita decrescente, depois `name`. Só entram vendedores com venda concluída no mês.

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/queries/reports/seller_breakdown_spec.rb
RSpec.describe Reports::SellerBreakdown do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }
  let(:a) { create(:product, organization: organization) }
  let!(:maria) { member("maria") }
  let!(:joao) { member("joao") }

  def member(username)
    create(:user, username: username).tap { |user| create(:membership, user: user, organization: organization, role: "manager") }
  end

  def sale(date, price, seller: nil, name: nil, status: "completed")
    create_report_sale(organization: organization, date: date, items: [ [ a, 1, price ] ], seller: seller, responsible_name: name, status: status)
  end

  def rows
    period = Reports::Period.new(month: Date.new(2026, 8, 1), comparison: "previous", today: today)
    described_class.new(scope: Reports::Scope.new(organization: organization), period: period).rows
  end

  before do
    sale(Date.new(2026, 7, 5), 20, seller: maria)
    sale(Date.new(2026, 7, 6), 10, name: "JOAO SILVA")
    sale(Date.new(2026, 8, 5), 10, seller: maria)
    sale(Date.new(2026, 8, 6), 20, seller: maria)
    sale(Date.new(2026, 8, 7), 15, name: "JOÃO SILVA")
    sale(Date.new(2026, 8, 8), 5, name: "Joao Silva")
    sale(Date.new(2026, 8, 9), 5)
    sale(Date.new(2026, 8, 10), 50, seller: maria, status: "pending")
  end

  it "groups completed sales by user, text name and unlinked" do
    expect(rows.map(&:to_h)).to eq([
      { key: "user:#{maria.id}", name: "maria", kind: :user, sales_count: 2, revenue: 30, share: 54.5, change: 50.0 },
      { key: "name:JOAO SILVA", name: "JOAO SILVA", kind: :name, sales_count: 2, revenue: 20, share: 36.4, change: 100.0 },
      { key: "none", name: "Não vinculado", kind: :none, sales_count: 1, revenue: 5, share: 9.1, change: nil }
    ])
  end

  it "keeps sales of a deleted user under their username as text" do
    pedro = member("pedro")
    sale(Date.new(2026, 8, 11), 1, seller: pedro)
    pedro.destroy!
    expect(rows.find { |row| row.key == "name:PEDRO" }).to have_attributes(name: "pedro", kind: :name)
  end

  it "keeps listing a seller who left the organization" do
    maria.memberships.destroy_all
    expect(rows.first).to have_attributes(name: "maria", kind: :user)
  end
end

# spec/queries/reports/seller_key_spec.rb
it "lists seller options: users, text names and unlinked" do
  joao = create(:user, username: "joao")
  maria = create(:user, username: "maria")
  [ joao, maria ].each { |user| create(:membership, user: user, organization: organization, role: "manager") }
  create_report_sale(organization: organization, date: Date.new(2026, 8, 1), items: [ [ product, 1, 1 ] ], responsible_name: "JOÃO SILVA")
  create_report_sale(organization: organization, date: Date.new(2026, 8, 2), items: [ [ product, 1, 1 ] ], responsible_name: "Joao Silva")

  expect(described_class.options(organization)).to eq([
    [ "joao", "user:#{joao.id}" ],
    [ "maria", "user:#{maria.id}" ],
    [ "JOÃO SILVA (sem cadastro)", "name:JOAO SILVA" ],
    [ "Não vinculado", "none" ]
  ])
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/queries/reports/seller_key_spec.rb spec/queries/reports/seller_breakdown_spec.rb`
Expected: FAIL (`uninitialized constant Reports::SellerBreakdown`, `undefined method 'options'`).

- [ ] **Step 3: Implement `SellerKey.name_labels`, `SellerKey.options` and `Reports::SellerBreakdown` per the rules**

- [ ] **Step 4: Run the tests to verify they pass**

Run: o comando do Step 2, depois `bin/rubocop app/queries/reports`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/queries/reports spec/queries/reports
git commit -m "feat: add seller breakdown for reports"
```

---

### Task 10: Página Relatórios com filtros e cards

**Files:**
- Create: `app/policies/report_policy.rb`, `app/controllers/reports_controller.rb`, `app/queries/reports/filters.rb`, `app/queries/reports/monthly_report.rb`, `app/views/reports/formatting.rb`, `app/views/reports/show.rb`, `app/views/reports/filters_component.rb`, `app/views/reports/metric_card_component.rb`
- Modify: `config/routes.rb`, `app/views/layouts/application_layout.rb`
- Test: `spec/policies/report_policy_spec.rb`, `spec/queries/reports/filters_spec.rb`, `spec/queries/reports/monthly_report_spec.rb`, `spec/views/reports/formatting_spec.rb`, `spec/requests/reports_spec.rb`

**Interfaces:**
- Consumes: tudo das Tasks 4 a 9
- Produces:
  - `ReportPolicy#show?`: `can_manage?`
  - `resource :report, only: :show` → `GET /report`, `report_path`
  - `ReportsController#show`:
    1. `authorize! :report`
    2. `Reports::Filters.new(params.permit(:month, :comparison, :product_id, :seller), organization: Current.organization)`
    3. `render Views::Reports::Show.new(report: Reports::MonthlyReport.new(organization: Current.organization, filters: filters))`
  - `Reports::Filters.new(params, organization:, today: Date.current)`, com:
    - `#period -> Reports::Period`: `month` no formato `"YYYY-MM"` via `Date.strptime`; inválido ou vazio vira o mês atual
    - `#product -> Product | nil`: só produto da organização
    - `#seller_key -> String | nil`: só chave que passa em `SellerKey.valid?`
  - `Reports::MonthlyReport.new(organization:, filters:)`, com:
    - `#period`, `#product`, `#seller_key`
    - `#summary -> Reports::Summary`, `#year_points`, `#product_rows`, `#seller_rows`
    - `#month_options -> Array<Date>`: em ordem decrescente, do mês atual até o menor entre o mês da primeira venda (qualquer status) e o mês escolhido
    - `#product_options`: produtos da organização por nome
    - `#seller_options`: igual a `SellerKey.options`
  - `Views::Reports::Formatting`, módulo Ruby puro (`ActiveSupport::NumberHelper` e `I18n`):
    - `currency(value) -> String`
    - `percent(value) -> String`
    - `change_text(change) -> String`
    - `change_tone(change, inverted: false) -> :positive | :negative | :neutral`
    - `period_label(range) -> String`
  - Componentes:
    - `Views::Reports::FiltersComponent.new(report:)`
    - `Views::Reports::MetricCardComponent.new(id:, title:, value:, comparisons:, detail: nil, inverted: false)`, com `comparisons` no formato `Array<{ change:, label: }>`
  - Item do menu lateral, logo depois de "Vendas": `{ label: "Relatórios", path: :report_path, controller: "reports", icon: PhlexIcons::Lucide::ChartColumn, rule: :show?, record: :report }`.
    - O layout da `main` já esconde itens com `rule:`, mas com `Membership` fixo em `sidebar_menu_item`. Acrescente `record: Membership` ao item "Funcionários" e troque a checagem por `allowed_to?(item[:rule], item[:record])`.
    - As abas do celular (`MOBILE_TAB_ITEMS`) não mudam; Relatórios fica no menu "Mais".

Conteúdo da página:

- **Cabeçalho:** `Components::PageHeader.new(title: "Relatórios", description: "Vendas concluídas de #{I18n.l(month, format: "%B de %Y")}.")`, dentro do contêiner padrão.
- **Filtros:** formulário GET para `report_path` com `data-controller="submit-on-change"` e `data-action="change->submit-on-change#submit"`, botão "Aplicar" e link "Limpar" (para `report_path`). Selects nativos, no padrão de `Views::Sales::Index#render_filters`:
  - `month`: valor `"YYYY-MM"`, rótulo `"%B de %Y"`
  - `comparison`: "Mês anterior" (`previous`) e "Mês atual" (`current`)
  - `product_id`: "Todos" e os produtos
  - `seller`: "Todos" e `seller_options`

  Cada select marca o valor efetivo.
- **Cards:**
  - Quatro: "Receita", "Vendas concluídas", "Unidades vendidas", "Ticket médio".
  - Mais dois: "Pendentes" e "Canceladas", com `inverted: true` e detalhe `"#{currency(value)} · #{percent(share)} das vendas do mês"`.
- **Comparações de cada card:**
  - A primeira é `{ change:, label: rótulo(janela da base) }`. Se `current_windows` existir, vem também `{ change: current_change, label: rótulo(janela do mês atual) }`.
  - `rótulo(janela)` é `period_label(janela)`, com `" (mesmos dias)"` no fim quando a janela não cobre o mês inteiro.
  - Com `change` presente o texto fica `"#{change_text} vs #{rótulo}"`; com `change` `nil`, `"Sem base em #{rótulo}"`.
- **Cores:** `:positive` em `text-green-700`, `:negative` em `text-red-700`, `:neutral` em `text-muted-foreground`.

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/policies/report_policy_spec.rb (mesmo padrão de sale_policy_spec)
RSpec.describe ReportPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:membership) { create(:membership, user: user, organization: organization, role: role) }
  let(:context) { { user: user, membership: membership, organization: organization } }
  let(:record) { :report }

  describe_rule :show? do
    %w[owner admin manager].each do |role_name|
      context "when membership is #{role_name}" do
        let(:role) { role_name }

        succeed
      end
    end

    context "when membership is viewer" do
      let(:role) { "viewer" }

      failed
    end
  end
end

# spec/views/reports/formatting_spec.rb
RSpec.describe Views::Reports::Formatting do
  subject(:format) { Class.new { include Views::Reports::Formatting }.new }

  it "formats money and percentages in pt-BR" do
    expect(format.currency(BigDecimal("1234.5"))).to eq("R$ 1.234,50")
    expect(format.percent(BigDecimal("63.2"))).to eq("63,2%")
    expect(format.percent(nil)).to eq("—")
  end

  it "formats changes with arrows and tones" do
    expect(format.change_text(BigDecimal("66.7"))).to eq("▲ 66,7%")
    expect(format.change_text(BigDecimal("-100"))).to eq("▼ 100,0%")
    expect(format.change_text(0)).to eq("0,0%")
    expect(format.change_text(nil)).to eq("—")
    expect(format.change_tone(BigDecimal("66.7"))).to eq(:positive)
    expect(format.change_tone(BigDecimal("66.7"), inverted: true)).to eq(:negative)
    expect(format.change_tone(nil)).to eq(:neutral)
  end

  it "labels whole and partial months" do
    expect(format.period_label(Date.new(2026, 7, 1)..Date.new(2026, 7, 31))).to eq("jul/2026")
    expect(format.period_label(Date.new(2026, 10, 1)..Date.new(2026, 10, 20))).to eq("1 a 20 de out/2026")
  end
end

# spec/queries/reports/filters_spec.rb
RSpec.describe Reports::Filters do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }
  let(:product) { create(:product, organization: organization) }

  def filters(params) = described_class.new(params, organization: organization, today: today)

  it "reads month, comparison, product and seller" do
    result = filters(ActionController::Parameters.new(month: "2026-08", comparison: "current", product_id: product.id.to_s, seller: "user:1").permit!)
    expect(result.period).to have_attributes(month: Date.new(2026, 8, 1), comparison: :current)
    expect(result.product).to eq(product)
    expect(result.seller_key).to eq("user:1")
  end

  it "falls back to defaults for invalid or foreign values" do
    [ "2026-13", "abc", "", "2027-01" ].each do |month|
      expect(filters(month: month).period.month).to eq(Date.new(2026, 10, 1))
    end
    expect(filters(product_id: create(:product).id).product).to be_nil
    expect(filters(seller: "garbage").seller_key).to be_nil
  end
end

# spec/queries/reports/monthly_report_spec.rb
RSpec.describe Reports::MonthlyReport do
  let(:today) { Date.new(2026, 10, 20) }
  let(:organization) { create(:organization) }

  def report(month: nil)
    described_class.new(organization: organization, filters: Reports::Filters.new({ month: month }, organization: organization, today: today))
  end

  it "offers months from the first sale to the current month" do
    create_report_sale(organization: organization, date: Date.new(2026, 6, 15), status: "pending", items: [ [ create(:product, organization: organization), 1, 1 ] ])
    expect(report.month_options).to eq([ 10, 9, 8, 7, 6 ].map { |m| Date.new(2026, m, 1) })
    expect(report(month: "2026-03").month_options.last).to eq(Date.new(2026, 3, 1))
  end

  it "offers only the current month without sales" do
    expect(report.month_options).to eq([ Date.new(2026, 10, 1) ])
  end
end

# spec/requests/reports_spec.rb
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

  it "renders an organization without sales" do
    get report_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("R$ 0,00", "Sem base em")
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/policies/report_policy_spec.rb spec/views/reports spec/queries/reports/filters_spec.rb spec/queries/reports/monthly_report_spec.rb spec/requests/reports_spec.rb`
Expected: FAIL (`uninitialized constant ReportPolicy`, ``undefined local variable or method `report_path'``).

- [ ] **Step 3: Implement** a policy, a rota, o controller, `Filters`, `MonthlyReport`, `Formatting`, a página com filtros e cards, e o item do menu, conforme as interfaces e o conteúdo acima.

- [ ] **Step 4: Run the tests to verify they pass**

Run: o comando do Step 2, depois `bin/rubocop app spec config/routes.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app config/routes.rb spec
git commit -m "feat: add reports page with filters and metric cards"
```

---

### Task 11: Gráfico do ano e tabelas de produtos e vendedores

**Files:**
- Create: `app/views/reports/year_chart_component.rb`, `app/views/reports/products_table_component.rb`, `app/views/reports/sellers_table_component.rb`
- Modify: `app/views/reports/show.rb`, `README.md`
- Test: `spec/requests/reports_spec.rb`

**Interfaces:**
- Consumes: `MonthlyReport#year_points/#product_rows/#seller_rows/#period`, `Views::Reports::Formatting`
- Produces:
  - `Views::Reports::YearChartComponent.new(points:, selected_month:)`
  - `Views::Reports::ProductsTableComponent.new(rows:, comparison_label:)`
  - `Views::Reports::SellersTableComponent.new(rows:, comparison_label:)`

O `comparison_label` é o mesmo rótulo da janela da base usado nos cards.

Conteúdo:

- **Gráfico:**
  - Título "Evolução em #{ano}" e descrição "Receita de vendas concluídas por mês e variação sobre o mês anterior."
  - 12 colunas. Altura da barra em `style="height: N%"`, relativa à maior receita do ano (zero quando todas são zero).
  - Acima da barra, `change_text` com a cor do tom; nada nos meses futuros. Abaixo, o mês abreviado ("ago").
  - `title` e texto `sr-only` no formato `"ago/2026: R$ 17,00"`.
  - Mês escolhido em `bg-green-600`, os outros em `bg-green-300`. Mês atual com "*" no rótulo e legenda "* mês atual, em andamento". Mês futuro sem barra.
- **Produtos:**
  - Colunas "Produto", "Qtd", "Receita", "% do total", "Variação".
  - Descrição "Todos os produtos já vendidos. Variação da quantidade contra #{comparison_label}."
  - Linha com quantidade zero em `text-muted-foreground`.
  - Variação: selo "novo" quando `first_sold_in_month`; senão `change_text` com a cor do tom.
  - Vazio: `Components::Listings::EmptyState` com ícone `Package`, título "Nenhum produto vendido ainda" e descrição "Os produtos aparecem aqui depois da primeira venda concluída."
- **Vendedores:**
  - Colunas "Vendedor", "Vendas", "Receita", "% do total", "Variação".
  - Descrição "Vendas concluídas por responsável. Variação da receita contra #{comparison_label}."
  - `kind: :name` mostra o nome seguido de "(sem cadastro)" em tom apagado; `kind: :none` mostra "Não vinculado" em tom apagado.
  - Vazio: `Components::Listings::EmptyState` com ícone `Users`, título "Nenhuma venda concluída neste mês" e descrição "Escolha outro mês ou remova os filtros."
- **Disposição:** gráfico em largura total; produtos e vendedores lado a lado em `xl:grid-cols-2`.
- **README:**
  - Bullet em "Funcionalidades Implementadas": "Relatórios mensais (owner, admin e manager): escolha do mês, comparação com o mês anterior ou com o mês atual (pelos mesmos dias), evolução no ano, produtos e vendedores."
  - Linha na tabela de "Autorização": `| Ver relatórios | Sim | Sim | Sim | Não |`.

- [ ] **Step 1: Write the failing test**

```ruby
it "renders the year chart, every sold product and the sellers" do
  travel_to(Time.zone.local(2026, 10, 20, 12)) do
    maria = create(:user, username: "maria")
    create(:membership, user: maria, organization: organization, role: "manager")
    alface = create(:product, organization: organization, name: "Alface")
    rucula = create(:product, organization: organization, name: "Rúcula")
    cheiro = create(:product, organization: organization, name: "Cheiro Verde")
    create_report_sale(organization: organization, date: Date.new(2026, 7, 10), items: [ [ alface, 4, 2 ], [ rucula, 5, 3 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 5), seller: maria, items: [ [ alface, 6, 2 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 10), responsible_name: "JOAO SILVA", items: [ [ cheiro, 3, 1 ] ])
    create_report_sale(organization: organization, date: Date.new(2026, 8, 12), items: [ [ alface, 1, 2 ] ])

    get report_path(month: "2026-08")

    expect(response.body).to include("Evolução em 2026", 'title="ago/2026: R$ 17,00"')
    expect(response.body).to include("Rúcula", "▼ 100,0%", "novo")
    expect(response.body).to include("Vendedor", "R$ 12,00", "JOAO SILVA", "(sem cadastro)")
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bundle exec rspec spec/requests/reports_spec.rb`
Expected: FAIL no teste novo.

- [ ] **Step 3: Implement the three components, render them in `Views::Reports::Show` and update the README**

- [ ] **Step 4: Run the full verification**

Run: `bundle exec rspec && bin/rubocop && bin/brakeman --no-pager`
Expected: tudo verde (562 examples da linha de base mais os novos, 0 failures), sem ofensas e sem avisos novos.

- [ ] **Step 5: Commit**

```bash
git add app/views/reports README.md spec/requests/reports_spec.rb
git commit -m "feat: add year chart and product and seller tables to reports"
```

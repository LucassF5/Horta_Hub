# Gestão de funcionários Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aba "Funcionários" onde owner/admin adicionam membros com senha gerada mostrada uma vez, trocam cargo, removem e geram nova senha, respeitando hierarquia de cargos.

**Architecture:** Hierarquia de cargos vive no model `Membership`; `MembershipPolicy` (ActionPolicy) decide quem pode o quê olhando o cargo atual e o cargo pretendido do registro; um objeto `Memberships::Creation` (ActiveModel) cuida de criar conta nova ou reaproveitar conta existente; `MembershipsController` escopado em `Current.organization`; views Phlex + RubyUI no padrão de Clientes.

**Tech Stack:** Rails 8.1, Ruby 4.0, ActionPolicy, Phlex + RubyUI, Turbo/Stimulus (importmap), RSpec + FactoryBot.

**Spec:** `docs/superpowers/specs/2026-10-20-gestao-de-funcionarios-design.md`

## Global Constraints

- Cargos: `owner` > `admin` > `manager` > `viewer`. Rótulos: Dono, Administrador, Gerente, Visualizador.
- Owner atribui qualquer cargo; admin atribui `admin`, `manager`, `viewer`. Manager e viewer não acessam a aba.
- Admin nunca altera, remove ou gera senha de owner. Ninguém age sobre a própria membership pela aba.
- Organização nunca fica sem owner.
- Senha gerada: 8 caracteres, `SecureRandom.alphanumeric(8)`. Nunca gravada em texto puro, nunca em flash/cookie/log, mostrada uma única vez.
- "Gerar nova senha" só se o membro pertence somente à organização atual; encerra todas as sessões dele.
- Remover apaga só a `Membership`. Se o usuário ficar sem membership em organização ativa, encerrar todas as sessões dele.
- Flash e textos em português. Convenções: `authorize!` em toda action, `params.expect`, escopo `Current.organization`.
- Antes de cada commit: `bundle exec rspec` verde e `bin/rubocop` limpo nos arquivos tocados. Baseline: 436 examples, 0 failures.

## Review Focus

1. E-mail de conta existente digitado com maiúsculas/espaços deve achar a conta existente, não falhar com "já está em uso". Teste na Task 3.
2. Parâmetro `role` manipulado (`owner` enviado por admin, ou valor inexistente como `superuser`) deve ser negado sem criar/alterar nada, sem erro 500. Testes nas Tasks 1, 2 e 5.
3. ID de membership de outra organização na URL (edit/update/destroy/reset_password) deve dar 404, nunca alterar. Teste na Task 6.
4. Recarregar ou voltar para a tela de senha não pode reexibir a senha: resposta com `Cache-Control: no-store`; reenviar o POST com o mesmo e-mail cai em "já é membro". Testes na Task 5.
5. Senha gerada precisa funcionar no login normal. Teste na Task 5 (login com a senha devolvida).

---

## File Structure

- Modify `app/models/membership.rb` — enum validado, hierarquia, rótulo, guarda de último owner, `sole_organization?`.
- Modify `app/models/user.rb` — geração e reset de senha, `member_of_active_organization?`.
- Create `app/policies/membership_policy.rb` — regras da aba.
- Create `app/services/memberships/creation.rb` — formulário/serviço de adicionar membro.
- Modify `app/controllers/concerns/authentication.rb` — fim do loop sem organização.
- Create `app/controllers/memberships_controller.rb`; modify `config/routes.rb`.
- Create `app/views/memberships/{index,new,edit,form_component,credentials}.rb`.
- Modify `app/views/layouts/application_layout.rb` — item da sidebar condicionado à policy.
- Create `app/javascript/controllers/clipboard_controller.js`.
- Modify `config/locales/pt-BR.yml` — rótulos de cargo e atributos.
- Tests: `spec/models/membership_spec.rb`, `spec/models/user_spec.rb`, `spec/policies/membership_policy_spec.rb`, `spec/services/memberships/creation_spec.rb`, `spec/requests/memberships_spec.rb`, `spec/requests/authentication_spec.rb` (novo), ajuste em `spec/requests/products_spec.rb:246-249`.

---

### Task 1: Hierarquia de cargos e senha no model

**Files:**
- Modify: `app/models/membership.rb`, `app/models/user.rb`, `config/locales/pt-BR.yml`
- Test: `spec/models/membership_spec.rb`, `spec/models/user_spec.rb` (criar ou estender)

**Interfaces:**
- Produces:
  - `Membership::ROLES_BY_RANK = %w[viewer manager admin owner].freeze`
  - `enum :role, {...}, validate: true` (valor inválido vira erro de validação, não `ArgumentError`)
  - `Membership#rank -> Integer` (índice em `ROLES_BY_RANK`)
  - `Membership#manages_members? -> Boolean` (owner ou admin)
  - `Membership#assignable_roles -> Array<String>` (owner: os 4; admin: `%w[admin manager viewer]`; demais: `[]`), ordenado do maior para o menor cargo
  - `Membership#can_act_on_role?(role) -> Boolean` (`role.to_s.in?(assignable_roles)`)
  - `Membership.role_label(role) -> String` e `Membership#role_label` via `I18n.t("activerecord.attributes.membership.roles.#{role}")`
  - `Membership#sole_organization? -> Boolean` (usuário não tem outra membership)
  - Guarda: validação em update impede que o último owner da organização deixe de ser owner (erro em `:role`, mensagem "a organização precisa de pelo menos um dono"); `before_destroy` impede destruir o último owner (`throw :abort` + erro em `:base` com a mesma mensagem)
  - `User.generate_password -> String` (`SecureRandom.alphanumeric(8)`)
  - `User#reset_password! -> String` (gera, salva `password`, `sessions.destroy_all`, devolve a senha em texto puro)
  - `User#member_of_active_organization? -> Boolean`

- [ ] **Step 1: Write failing specs**

`spec/models/membership_spec.rb`:
- `it "orders roles by rank"`: `build(:membership, role: "owner").rank > build(:membership, :admin).rank > ... :manager > ... :viewer`.
- `it "lets owner assign every role"`: `expect(build(:membership).assignable_roles).to eq(%w[owner admin manager viewer])`.
- `it "lets admin assign admin, manager and viewer"`: `eq(%w[admin manager viewer])`.
- `it "lets manager and viewer assign nothing"`: `eq([])` para ambos.
- `it "rejects an unknown role without raising"`: `m = build(:membership, role: "superuser"); expect(m).not_to be_valid; expect(m.errors[:role]).to be_present`.
- `it "labels roles in Portuguese"`: `Membership.role_label("owner") == "Dono"`, `"admin" => "Administrador"`, `"manager" => "Gerente"`, `"viewer" => "Visualizador"`.
- `describe "last owner guard"`: com único owner `o` na organização: `o.update(role: "admin")` retorna `false` e `o.reload.owner?`; `o.destroy` retorna `false` e `Membership.exists?(o.id)`. Com dois owners: rebaixar e destruir um deles funciona.
- `it "detects sole organization"`: `true` com uma membership; `false` após criar membership do mesmo usuário em outra organização.

`spec/models/user_spec.rb`:
- `it "generates 8-character alphanumeric passwords"`: `expect(User.generate_password).to match(/\A[a-zA-Z0-9]{8}\z/)`.
- `it "resets the password and ends sessions"`: user com 2 sessions; `pw = user.reset_password!`; `expect(user.reload.authenticate(pw)).to be_truthy`; `expect(user.authenticate("password123")).to be false`; `expect(user.sessions.count).to eq(0)`.
- `it "knows whether it belongs to an active organization"`: `false` sem memberships; `false` só com organização `inactive`; `true` com organização ativa.

- [ ] **Step 2: Run** `bundle exec rspec spec/models/membership_spec.rb spec/models/user_spec.rb` — Expected: FAIL (métodos indefinidos).

- [ ] **Step 3: Implement** as interfaces acima. Locale em `pt-BR.yml` sob `activerecord.attributes.membership`: `role: "Cargo"` e `roles: { owner: "Dono", admin: "Administrador", manager: "Gerente", viewer: "Visualizador" }`; sob `activerecord.attributes.user`: `username: "Nome de usuário"`, `email_address: "E-mail"`. Contagem do último owner: `organization.memberships.owner.where.not(id: id).none?` (usar `role_in_database`/`role_was` para saber se era owner).

- [ ] **Step 4: Run** mesmo comando — Expected: PASS. Depois `bundle exec rspec` — Expected: 0 failures.

- [ ] **Step 5: Commit** `feat: add role hierarchy and password reset to memberships`

---

### Task 2: MembershipPolicy

**Files:**
- Create: `app/policies/membership_policy.rb`
- Test: `spec/policies/membership_policy_spec.rb` (mesmo formato de `spec/policies/client_policy_spec.rb`)

**Interfaces:**
- Consumes: Task 1 (`manages_members?`, `can_act_on_role?`, `sole_organization?`).
- Produces rules (contexto `membership` = ator; `record` = membership alvo, ou a classe `Membership` em `index?`):
  - `index?`: `membership.manages_members?`
  - `create?` (alias `new?`): `manages_members? && same_organization? && can_act_on_role?(record.role)`
  - `update?` (alias `edit?`): `manages_members? && same_organization? && !own_record? && can_act_on_role?(record.role_in_database) && can_act_on_role?(record.role)`
  - `destroy?`: `manages_members? && same_organization? && !own_record? && can_act_on_role?(record.role_in_database)`
  - `reset_password?`: `destroy?` `&& record.sole_organization?`
  - private `own_record?`: `record.id == membership.id`

- [ ] **Step 1: Write failing spec** com `describe_rule` para cada regra:
  - `index?`: succeed owner/admin; failed manager/viewer.
  - `create?`: owner criando `owner` succeed; admin criando `admin`/`manager`/`viewer` succeed; admin criando `owner` failed; admin criando `superuser` failed; manager criando `viewer` failed; record de outra organização failed.
  - `update?`: owner muda viewer→admin succeed; admin muda manager→viewer succeed; admin muda admin→viewer (outro admin) succeed; admin muda viewer→owner failed; admin edita owner failed; owner edita a própria membership failed; outra organização failed.
  - `destroy?`: owner remove admin succeed; admin remove owner failed; owner remove a si failed; manager remove viewer failed.
  - `reset_password?`: owner em viewer de organização única succeed; mesmo viewer com membership em outra organização failed; admin em owner failed; em si mesmo failed.
- [ ] **Step 2: Run** `bundle exec rspec spec/policies/membership_policy_spec.rb` — Expected: FAIL (`MembershipPolicy` não existe).
- [ ] **Step 3: Implement** a policy acima.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat: add membership policy`

---

### Task 3: Memberships::Creation

**Files:**
- Create: `app/services/memberships/creation.rb`
- Test: `spec/services/memberships/creation_spec.rb`

**Interfaces:**
- Consumes: Task 1 (`User.generate_password`, enum validado).
- Produces `Memberships::Creation` (`include ActiveModel::Model`, `ActiveModel::Attributes`):
  - `new(organization:, username: nil, email_address: nil, role: "viewer")`
  - `model_name` → `"Member"` (param key `member`, para `form_with(model:, scope: :member)` e `params.expect(member: [...])`)
  - `#membership -> Membership` (memoizado; `organization.memberships.build(role:)`, usado pelo controller em `authorize!` antes do save)
  - `#save -> Boolean`
  - `#generated_password -> String | nil` (só preenchido quando criou conta nova)
  - `#existing_user? -> Boolean`
  - `#errors` com mensagens em português para exibir na view

Comportamento de `save`:
1. Procura `User.find_by(email_address:)` (o `normalizes` do `User` normaliza a busca).
2. Achou e já é membro da organização: `errors.add(:email_address, "já pertence a esta organização")`, retorna `false`.
3. Achou: atribui `membership.user = user`, salva membership; `generated_password` fica `nil`.
4. Não achou: dentro de `ActiveRecord::Base.transaction`, cria `User` com `username`, `email_address`, `password: User.generate_password`, depois a membership. Erros de `User`/`Membership` copiados para `errors` (atributos `username`, `email_address`, `role`). Nada fica gravado se qualquer save falhar.

- [ ] **Step 1: Write failing spec:**
  - `it "creates a user and membership with a generated password"`: muda `User.count` e `Membership.count` em 1; `generated_password` casa `/\A[a-zA-Z0-9]{8}\z/`; `User.last.authenticate(creation.generated_password)` truthy; `membership.role == "manager"` quando `role: "manager"`.
  - `it "reuses an existing account"`: user existente em outra organização; `email_address: "  #{user.email_address.upcase} "`; não muda `User.count`; muda `Membership.count` em 1; `existing_user?` true; `generated_password` nil; senha antiga continua autenticando; `username` do user não muda.
  - `it "rejects an account already in the organization"`: `save` false; `errors[:email_address]` inclui "já pertence a esta organização"; nada criado.
  - `it "rolls back the user when the membership is invalid"`: `role: "superuser"`; `save` false; `User.count` não muda.
  - `it "reports user validation errors"`: `username: "ab"` → `save` false; `errors[:username]` presente.
- [ ] **Step 2: Run** `bundle exec rspec spec/services/memberships/creation_spec.rb` — Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat: add member creation service`

---

### Task 4: Fim do loop de usuário sem organização

**Files:**
- Modify: `app/controllers/concerns/authentication.rb:57-65` (`set_current_organization`)
- Modify: `spec/requests/products_spec.rb:246-249`
- Test: `spec/requests/authentication_spec.rb` (novo; usa `sign_in` de `spec/support/authentication_helper.rb`, sem stubs de `Current`)

**Interfaces:**
- Produces: quando `Current.organization` é `nil`, `terminate_session` e `redirect_to new_session_path, alert: "Você não pertence a nenhuma organização."`. Substitui o redirect atual para `new_organization_path`.

- [ ] **Step 1: Write failing spec** `spec/requests/authentication_spec.rb`:
  - `it "logs out a user without organizations"`: `sign_in(create(:user))`; `get root_path`; `expect(response).to redirect_to(new_session_path)`; `follow_redirect!`; `expect(response.body).to include("Você não pertence a nenhuma organização.")`; `expect(Session.count).to eq(0)`.
  - `it "logs out a user whose only organization is inactive"`: mesma expectativa.
  - Atualizar `products_spec.rb` "redirects to new organization page" para `"logs the user out"` e `redirect_to(new_session_path)`.
- [ ] **Step 2: Run** `bundle exec rspec spec/requests/authentication_spec.rb spec/requests/products_spec.rb` — Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `bundle exec rspec` — Expected: 0 failures.
- [ ] **Step 5: Commit** `fix: log out users without an active organization`

---

### Task 5: Listar e adicionar funcionários

**Files:**
- Create: `app/controllers/memberships_controller.rb`, `app/views/memberships/index.rb`, `app/views/memberships/new.rb`, `app/views/memberships/form_component.rb`, `app/views/memberships/credentials.rb`, `app/javascript/controllers/clipboard_controller.js`
- Modify: `config/routes.rb`, `app/views/layouts/application_layout.rb:17-23` e `sidebar_menu_item`
- Test: `spec/requests/memberships_spec.rb`

**Interfaces:**
- Consumes: Tasks 1-3.
- Produces:
  - Rotas: `resources :memberships, only: %i[index new create edit update destroy] do post :reset_password, on: :member end` (edit/update/destroy/reset_password implementados na Task 6).
  - `MembershipsController#index`: `authorize!`; `Current.organization.memberships.includes(:user)` ordenado por rank decrescente e depois `users.username`.
  - `#new`: `@creation = Memberships::Creation.new(organization: Current.organization)`; `authorize! @creation.membership`.
  - `#create`: `Memberships::Creation.new(organization: Current.organization, **member_params)`; `authorize! @creation.membership`; se `save` e conta nova: `response.headers["Cache-Control"] = "no-store"` e `render Views::Memberships::Credentials.new(membership:, password:, notice: "Funcionário adicionado com sucesso.")` com status 200; se `save` e conta existente: `redirect_to memberships_path, notice: "Usuário já existente adicionado à organização."`; senão render `New` com `:unprocessable_entity`.
  - `member_params`: `params.expect(member: [ :username, :email_address, :role ])`.
  - `Views::Memberships::Credentials.new(membership:, password:, notice:)` — reutilizada na Task 6. Mostra nome de usuário, e-mail, senha num campo `readonly`, botão "Copiar senha", aviso "Esta senha não será mostrada novamente. Copie e repasse ao funcionário.", link "Voltar para funcionários".
  - `Views::Memberships::FormComponent.new(creation:, url:)`: campos nome de usuário, e-mail, select de cargo com `Current.membership.assignable_roles` e rótulos `Membership.role_label`. `form_with(... data: { turbo: false })` para que a resposta 200 com a senha seja renderizada (Turbo rejeita 200 em submit).
  - Index: título "Funcionários", link "Novo funcionário" se `allowed_to?(:index?, Membership)` (quem vê a aba pode adicionar ao menos `viewer`), tabela Nome de usuário / E-mail / Cargo / Ações. Ações da Task 6 entram depois.
  - Sidebar: item `{ label: "Funcionários", path: :memberships_path, controller: "memberships", icon: PhlexIcons::Lucide::UserCog, rule: :index? }` após "Importações"; `sidebar_menu_item` pula itens com `rule` quando `!allowed_to?(item[:rule], Membership)`.
  - `clipboard_controller.js`: targets `source`; action `copy` faz `navigator.clipboard.writeText(this.sourceTarget.value)` e troca o texto do botão para "Copiado!".

- [ ] **Step 1: Write failing request spec** (setup igual a `spec/requests/clients_spec.rb`, `role` variável):
  - owner `GET /memberships`: 200, inclui "Funcionários", e-mail do membro e "Dono".
  - manager e viewer `GET /memberships` e `GET /memberships/new`: redirect `root_path` com alerta "Você não tem permissão"; sidebar (`GET /clients`) não contém "Funcionários".
  - owner/admin `GET /clients`: sidebar contém "Funcionários".
  - owner `POST /memberships` conta nova (`role: "viewer"`): 200; muda `User.count` em 1; `response.headers["Cache-Control"]` inclui `"no-store"`; corpo inclui "Esta senha não será mostrada novamente"; extrair senha do corpo (`/value="([A-Za-z0-9]{8})"/`) e `post session_path, params: { email_address:, password: }` (sem stubs — usar um bloco `context` separado sem os stubs de `Current`, com `sign_in`) redireciona para `root_path`.
  - `POST` com e-mail existente de outra organização: redirect `memberships_path`, notice "Usuário já existente adicionado à organização."; `User.count` igual.
  - Reenviar o mesmo POST: 422, inclui "já pertence a esta organização"; `Membership.count` igual.
  - admin `POST` com `role: "owner"`: redirect `root_path`; nada criado. Com `role: "superuser"`: sem 500, nada criado.
  - Nenhuma senha gerada aparece no flash: depois do POST de conta nova, `get memberships_path` não inclui a senha extraída.
- [ ] **Step 2: Run** `bundle exec rspec spec/requests/memberships_spec.rb` — Expected: FAIL (rota inexistente).
- [ ] **Step 3: Implement** controller, rotas, views, sidebar, Stimulus.
- [ ] **Step 4: Run** `bundle exec rspec` e `bin/rubocop` — Expected: 0 failures, sem ofensas.
- [ ] **Step 5: Commit** `feat: list and add organization members`

---

### Task 6: Trocar cargo, remover e gerar nova senha

**Files:**
- Modify: `app/controllers/memberships_controller.rb`, `app/views/memberships/index.rb`
- Create: `app/views/memberships/edit.rb`
- Test: `spec/requests/memberships_spec.rb`

**Interfaces:**
- Consumes: Tasks 1, 2, 5 (`Views::Memberships::Credentials`).
- Produces:
  - `before_action :set_membership` (edit/update/destroy/reset_password): `Current.organization.memberships.includes(:user).find(params[:id])` (outra organização → 404).
  - `#edit`: `authorize!`; render `Views::Memberships::Edit` com select de cargo (`Current.membership.assignable_roles`).
  - `#update`: `@membership.role = params.expect(membership: [ :role ])[:role]`; `authorize! @membership`; `save` → `redirect_to memberships_path, notice: "Cargo atualizado com sucesso."`; falha → render `Edit` com 422.
  - `#destroy`: `authorize!`; `destroy`; se `!user.member_of_active_organization?` então `user.sessions.destroy_all`; `redirect_to memberships_path, notice: "Funcionário removido da organização.", status: :see_other`. Se `destroy` falhar (guarda de último owner): redirect com alert da mensagem de erro.
  - `#reset_password`: `authorize!`; `password = @membership.user.reset_password!`; `no-store`; render `Credentials` com notice "Nova senha gerada com sucesso."
  - Index: por linha, "Editar" se `allowed_to?(:edit?, m)`, "Gerar nova senha" (form POST com `data: { turbo: false }`, sem confirmação, porque `turbo_confirm` não roda com Turbo desligado) se `allowed_to?(:reset_password?, m)`, "Remover" (DELETE com `turbo_confirm: "Tem certeza?"`) se `allowed_to?(:destroy?, m)`.

- [ ] **Step 1: Write failing request specs:**
  - owner `PATCH` viewer→manager: redirect `memberships_path`, notice, `reload.manager?`.
  - admin `PATCH` viewer→owner: redirect `root_path`, papel inalterado. admin `GET edit` de um owner: redirect `root_path`.
  - owner `PATCH` na própria membership: redirect `root_path`.
  - `PATCH`/`DELETE`/`POST reset_password` com membership de outra organização: `404` (`have_http_status(:not_found)`), nada muda.
  - owner `DELETE` de viewer que só pertence a esta organização: `Membership.count` -1, `User.count` igual, sessões do viewer zeradas.
  - owner `DELETE` de viewer que pertence também a outra organização ativa: sessões do viewer mantidas.
  - owner `POST reset_password` em viewer de organização única: 200, `no-store`, senha extraída autentica `viewer.user.reload`, sessões do viewer zeradas.
  - `POST reset_password` em viewer com outra organização: redirect `root_path`, senha antiga ainda autentica.
  - index para owner mostra "Editar", "Remover", "Gerar nova senha" para o viewer, e nenhuma ação na linha do próprio owner; para admin, nenhuma ação na linha do owner.
- [ ] **Step 2: Run** `bundle exec rspec spec/requests/memberships_spec.rb` — Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `bundle exec rspec`, `bin/rubocop`, `bin/brakeman --no-pager` — Expected: 0 failures, sem ofensas, sem warnings novos.
- [ ] **Step 5: Commit** `feat: change role, remove and reset password of members`

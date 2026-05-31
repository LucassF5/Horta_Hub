---
name: novo-recurso-crud
description: "Cria um novo recurso CRUD completo no Horta Hub. Use quando precisar adicionar uma nova entidade/recurso ao sistema com migration, model, controller, views Phlex e specs. Inclui: migration com foreign key para organization, model com validações, controller RESTful escopado, views Phlex com RubyUI, factory, model spec e request spec."
argument-hint: "Nome do recurso e seus campos (ex: 'Canteiro com nome:string, tamanho:decimal, tipo:enum')"
---

# Criar Novo Recurso CRUD

Workflow completo para criar um novo recurso no Horta Hub seguindo todas as convenções do projeto.

## Quando Usar

- Adicionar uma nova entidade ao sistema (ex: Canteiro, Colheita, Plantio)
- Criar CRUD completo com todas as camadas

## Procedimento

### 1. Migration

Criar migration em `db/migrate/`:

- Tabela com campos solicitados
- `t.references :organization, null: false, foreign_key: true`
- Índice único composto quando necessário
- Enums como `t.string` com default
- Decimais com `precision: 10, scale: 2`
- Rodar `rails db:migrate`

### 2. Model

Criar em `app/models/nome_do_recurso.rb`:

- `belongs_to :organization`
- Enums com hash de string
- Normalizations para campos de texto
- Validações (presence, length, uniqueness scoped to org)
- Ordem: associations → enums → normalizations → validations → callbacks → scopes → métodos

### 3. Controller

Criar em `app/controllers/nome_do_recursos_controller.rb`:

- Herdar de `ApplicationController`
- `before_action :set_resource` para show/edit/update/destroy
- Todas as 7 actions RESTful
- Escopo: `Current.organization.recursos`
- Strong params: `params.expect(recurso: [...])`
- Render Phlex views
- Flash messages em português

### 4. Rotas

Adicionar em `config/routes.rb`:

```ruby
resources :nome_do_recursos
```

### 5. Views Phlex

Criar em `app/views/nome_do_recurso/`:

- `index.rb` — listagem com cards RubyUI
- `show.rb` — detalhes do recurso
- `new.rb` — formulário de criação
- `edit.rb` — formulário de edição
- `_form.rb` ou form inline — campos do formulário com RubyUI::Input/Select/Form

Convenções das views:
- Classe: `Views::NomeDoRecurso::Action < Views::Base`
- `initialize` recebe dados necessários
- `view_template` como método principal
- Seções privadas: `render_header`, `render_form`, etc.
- Componentes RubyUI para UI
- TailwindCSS para layout

### 6. Factory

Criar em `spec/factories/nome_do_recursos.rb`:

- Campos com `sequence` ou `Faker`
- `association :organization`
- Traits para variações comuns

### 7. Model Spec

Criar em `spec/models/nome_do_recurso_spec.rb`:

- Testar associations com shoulda-matchers
- Testar validações com shoulda-matchers
- Testar normalizations manualmente
- Testar métodos customizados

### 8. Request Spec

Criar em `spec/requests/nome_do_recursos_spec.rb`:

- `sign_in(user)` com user `:with_organization`
- Testar todas as actions: GET index, GET show, GET new, POST create, GET edit, PATCH update, DELETE destroy
- Contextos: parâmetros válidos e inválidos
- Verificar HTTP status, redirects, flash messages
- Verificar criação/atualização/remoção no banco

### 9. Validação Final

- `rails db:migrate`
- `bundle exec rspec spec/models/nome_do_recurso_spec.rb spec/requests/nome_do_recursos_spec.rb`
- `rubocop -a`
- Verificar que tudo passa

## Checklist

- [ ] Migration criada e executada
- [ ] Model com associations e validações
- [ ] Controller RESTful com escopo de organização
- [ ] Rotas adicionadas
- [ ] Views Phlex para todas as actions
- [ ] Factory criada
- [ ] Model spec passando
- [ ] Request spec passando
- [ ] RuboCop sem ofensas

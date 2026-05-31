# Horta Hub — Copilot Instructions

## Projeto

Sistema multi-organização para gestão de hortas urbanas. Rails 8.1, Phlex views, RubyUI, Hotwire (Turbo + Stimulus), TailwindCSS, SQLite.

## Idioma

- Código (classes, métodos, variáveis): **inglês**
- Textos visíveis ao usuário (flash messages, labels, placeholders): **português (pt-BR)**
- Comentários de código: **português** quando necessário, preferencialmente o código deve ser autoexplicativo
- Commits e PRs: **português**

## Stack & Convenções Gerais

- Ruby 3.x, Rails 8.1
- Views em **Phlex** (NÃO usar ERB). Todas as views herdam de `Views::Base`
- Componentes de UI via **RubyUI** (Button, Card, Form, Input, Link, Select, etc.)
- Layout principal: `Views::Layouts::ApplicationLayout` (Phlex)
- Assets via `importmap-rails` (sem Node.js)
- Estilização com **TailwindCSS** via classes utilitárias
- Background jobs: `solid_queue`
- Caching: `solid_cache`
- Testes: **RSpec** + FactoryBot + Shoulda Matchers + Capybara
- Linting: `rubocop-rails-omakase`
- Segurança: `brakeman`
- Locale padrão: `pt-BR`

## Autenticação

- `has_secure_password` (bcrypt) — sem Devise
- Concern `Authentication` no `ApplicationController`
- Session via cookie assinado (`cookies.signed[:session_id]`)
- `Current.user`, `Current.session`, `Current.organization` (thread-local)
- Helper `sign_in(user)` e `sign_out` nos specs de request/system

## Multi-organização

- Todos os recursos pertencem a uma `Organization` via `belongs_to :organization`
- Escopo obrigatório: `Current.organization.resources` (nunca buscar sem escopo)
- Roles via `Membership`: `owner`, `admin`, `manager`, `viewer`
- `can_manage?` retorna true para owner/admin/manager
- `read_only?` retorna true para viewer

## Padrões de Código

### Models
- Validações explícitas com mensagens quando necessário
- Enums com hash de string: `enum :status, { active: "active" }`
- Normalizations: `normalizes :field, with: -> (v) { v.strip.downcase }`
- Associations com `dependent:` sempre definido
- Scopes por organização quando relevante

### Controllers
- RESTful, 7 actions padrão
- `before_action :set_resource` para show/edit/update/destroy
- Strong params com `params.expect(resource: [...])` (sintaxe Rails 8)
- Render Phlex views: `render Views::Resource::Action.new(args)`
- Flash messages em português
- Resources sempre escopados: `Current.organization.resources`

### Views (Phlex)
- Namespace: `Views::NomeDoRecurso::Action`
- Arquivo: `app/views/nome_do_recurso/action.rb`
- Herdam de `Views::Base`
- Métodos privados `render_*` para seções da view
- Helpers acessíveis via `helpers.method_name`
- RubyUI para componentes: `render RubyUI::Button.new(...)`

### Specs
- Model specs: shoulda-matchers para associations/validations
- Request specs: testar HTTP responses, redirects, flash
- Factories com traits: `:with_organization`, `:admin`, `:expensive`
- `sign_in(user)` antes de requests autenticados
- `Faker` para dados dinâmicos

## Regras Importantes

1. **Nunca usar ERB** — apenas Phlex (exceção: mailer views em `app/views/*_mailer/` usam ERB)
2. **Nunca buscar recursos sem escopo de organização**
3. **Sempre adicionar testes** ao criar/modificar funcionalidades
4. **Sempre usar I18n** para textos visíveis ao usuário quando possível
5. **Seguir as convenções do RuboCop** (rubocop-rails-omakase)
6. **Migrations reversíveis** — sempre que possível

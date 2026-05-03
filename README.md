# Horta Hub

Aplicação Rails minimalista para gerenciar produtos e clientes, com autenticação e componentes Phlex/Tailwind.

## Sumário
- [Visão Geral](#visão-geral)
- [Pré-requisitos](#pré-requisitos)
- [Configuração Rápida](#configuração-rápida)
- [Banco de dados](#banco-de-dados)
- [Executando a Aplicação](#executando-a-aplicação)
- [Testes](#testes)
- [Features Implementadas](#features-implementadas)
- [Melhorias Recomendadas](#melhorias-recomendadas)
- [Futuras Implementações](#futuras-implementações)
- [Checklist Privado](#checklist-privado)

## Visão Geral

Este repositório contém a aplicação `Horta_Hub` — uma base para gerenciamento de produtos e clientes com autenticação baseada em senha e uma UI composta por componentes `RubyUI` (Phlex + Tailwind).

## Pré-requisitos

- Ruby 3.x / Rails 8.x
- SQLite (desenvolvimento) ou outro banco suportado
- Node/npm apenas se você for compilar assets locais (opcional com importmap)

## Configuração Rápida

1. Instale dependências Ruby:

```bash
bundle install
```

2. Configure variáveis de ambiente necessárias (ex.: `RAILS_ENV`, `DATABASE_URL`) e a chave mestra se aplicável (`/config/master.key`).

3. Crie/atualize o banco de dados:

```bash
rails db:create db:migrate db:seed
```

## Banco de dados

O projeto usa migrations em `db/migrate/`. Em desenvolvimento o SQLite é usado por padrão; para produção configure `DATABASE_URL` com Postgres/MySQL conforme necessário.

## Executando a Aplicação

Inicie o servidor Puma:

```bash
bin/rails server
```

Acesse http://localhost:3000

## Testes

Ainda não há uma suíte de testes completa; recomenda-se adicionar `rspec-rails` ou `minitest` e configurar CI para rodar testes, RuboCop e Brakeman.

## Features Implementadas

- Autenticação com `has_secure_password` e sessões persistidas em `Session`.
- Fluxo de recuperação de senha (mailer + templates; falta gerar/validar token no `User`).
- CRUD de `Product` e `Client` com validações básicas.
- UI componetizada com `RubyUI` (Phlex) e Tailwind.
- Esqueleto PWA (`manifest` e `service-worker.js`) disponível, não ativado por padrão.

## Melhorias Recomendadas (curto prazo)

- Consertar `UsersController#create` para não usar `create!` seguido de `save`.
- Implementar `password_reset_token` seguro (usar `signed_id` ou `has_secure_token`) e expiração.
- Substituir `params.expect` por `params.require(...).permit(...)` e evitar `update!` em condicionais.
- Ativar manifest no layout e testar `service-worker` para funcionalidades PWA.

## Futuras Implementações (médio/longo prazo)

- Painel Admin com controle de permissões por `role`.
- API JSON versionada com autenticação JWT.
- Pesquisa e paginação (Pagy/Kaminari), import/export CSV, Web Push, 2FA, OAuth social.

## Checklist Privado

Existe um checklist local com melhorias e ideias em `CHECKLIST.md` (não comitado por padrão).

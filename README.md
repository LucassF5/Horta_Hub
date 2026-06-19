# Horta Hub

Aplicação Rails para gerenciar organizações, produtos, clientes e vendas, com autenticação, autorização por papel e interface server-rendered em Phlex.

## Tecnologias

- Ruby on Rails 8.1
- SQLite
- Phlex, RubyUI e Tailwind CSS
- Hotwire com Turbo e Stimulus
- RSpec
- Action Policy
- FriendlyId

## Funcionalidades Implementadas

- Cadastro de organização e usuário proprietário em uma única transação.
- Autenticação por senha e sessões persistidas em `Session`.
- Recuperação de senha com token assinado e expiração fornecidos por `has_secure_password`.
- Usuários vinculados a múltiplas organizações por `Membership`.
- Seleção da organização ativa pela sessão.
- Papéis `owner`, `admin`, `manager` e `viewer` por organização.
- CRUD de produtos e clientes com slugs amigáveis escopados por organização.
- CRUD de vendas com cliente, status, observações e itens de venda.
- Cálculo do total da venda a partir dos itens.
- Isolamento das consultas por `Current.organization`.
- Autorização de produtos, clientes e vendas com Action Policy.
- Controles de interface condicionados por `allowed_to?`.
- Testes de models, requests e policies com RSpec.

## Autorização

As permissões são determinadas pela `Membership` do usuário na organização ativa.

| Ação | owner | admin | manager | viewer |
| --- | --- | --- | --- | --- |
| Listar e visualizar | Sim | Sim | Sim | Sim |
| Criar | Sim | Sim | Sim | Não |
| Editar | Sim | Sim | Sim | Não |
| Excluir | Sim | Sim | Sim | Não |

Regras adicionais:

- Um recurso só pode ser visualizado ou alterado dentro da organização à qual pertence.
- Produtos utilizados em vendas não podem ser excluídos.
- Clientes vinculados a vendas não podem ser excluídos.
- `SaleItem` é autorizado como parte de `Sale`, pois não possui rotas independentes.
- O backend sempre executa `authorize!`; os controles do frontend servem apenas para adequar a experiência do usuário.

## Configuração

Instale as dependências e prepare o banco:

```bash
bundle install
bin/rails db:prepare
```

Inicie a aplicação:

```bash
bin/dev
```

A aplicação estará disponível em `http://localhost:3000`.

## Seed e População do Banco

Para popular um banco já preparado com os dados de demonstração:

```bash
bin/rails db:seed
```

O seed é idempotente e pode ser executado novamente sem duplicar os registros principais. Ele cria ou atualiza:

- uma organização de demonstração;
- um usuário proprietário;
- 10 produtos;
- 6 clientes;
- 6 vendas com seus respectivos itens.

Credenciais para acessar os dados de demonstração:

```text
E-mail: admin@hortahub.test
Senha: password123
```

Para apagar o banco de desenvolvimento, recriar a estrutura e executar o seed novamente:

```bash
bin/rails db:reset
```

O comando `db:reset` remove os dados existentes. Não o execute em produção.

## Qualidade

Execute a suíte de testes:

```bash
bundle exec rspec
```

Execute as verificações estáticas:

```bash
bin/rubocop
bin/brakeman
```

## Próximos Passos

As implementações futuras estão registradas em [CHECKLIST.md](CHECKLIST.md). O checklist contém apenas pendências; funcionalidades concluídas permanecem documentadas neste artigo.

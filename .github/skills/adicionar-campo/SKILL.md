---
name: adicionar-campo
description: "Adiciona um novo campo a um recurso existente no Horta Hub. Use quando precisar adicionar coluna, validação, atualizar views e specs de um model existente. Cobre migration, model, controller (strong params), views e testes."
argument-hint: "Nome do recurso e campo a adicionar (ex: 'Product com description:text')"
---

# Adicionar Campo a Recurso Existente

Workflow para adicionar um novo campo a um recurso já existente, atualizando todas as camadas.

## Quando Usar

- Adicionar nova coluna a uma tabela existente
- Atualizar model, controller, views e specs para refletir o novo campo

## Procedimento

### 1. Migration

```ruby
class AddFieldToResources < ActiveRecord::Migration[8.1]
  def change
    add_column :resources, :field_name, :type, options
  end
end
```

- Rodar `rails db:migrate`

### 2. Model

- Adicionar validações para o novo campo (se necessário)
- Adicionar normalizations (se campo de texto)
- Atualizar enums (se campo enum)

### 3. Controller

- Adicionar campo ao `params.expect` nos strong params

### 4. Views

- Adicionar campo nos formulários (new/edit)
- Adicionar campo na exibição (show/index)
- Usar componente RubyUI apropriado (Input, Select, Textarea)

### 5. Specs

- Atualizar model spec com novas validações
- Atualizar factory com o novo campo
- Atualizar request spec para incluir o campo nos parâmetros

### 6. Validação

- `bundle exec rspec`
- `rubocop -a`

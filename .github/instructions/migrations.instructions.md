---
description: "Use ao criar migrations Rails. Cobre criação de tabelas, índices, foreign keys e convenções do projeto."
applyTo: "db/migrate/**/*.rb"
---

# Padrão de Migrations

## Convenções

- Migrations **reversíveis** sempre que possível
- Todo recurso precisa de `references :organization, foreign_key: true`
- Adicionar `index` para foreign keys e campos de busca frequente
- Usar `unique: true` em índices compostos quando necessário (ex: nome + organization)
- Enums como strings: `t.string :status, default: "active", null: false`
- Decimais para preços: `t.decimal :price, precision: 10, scale: 2`

## Exemplo — Novo Recurso

```ruby
class CreateResources < ActiveRecord::Migration[8.1]
  def change
    create_table :resources do |t|
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :status, default: "active", null: false
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end

    add_index :resources, [:organization_id, :name], unique: true
  end
end
```

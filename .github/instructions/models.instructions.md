---
description: "Use ao criar ou editar models Rails. Cobre validações, associations, enums, normalizations e escopo por organização."
applyTo: "app/models/**/*.rb"
---

# Padrão de Models

## Estrutura do arquivo

Seguir esta ordem no model:

1. `has_secure_password` (se aplicável)
2. Associations (`belongs_to`, `has_many`, `has_one`)
3. Enums
4. Normalizations
5. Validações
6. Callbacks (usar com parcimônia)
7. Scopes
8. Métodos públicos
9. Métodos privados

## Convenções

- Todo recurso pertence a `Organization`: `belongs_to :organization`
- Associations sempre com `dependent:` definido
- Enums com hash de string: `enum :role, { admin: "admin", viewer: "viewer" }`
- Normalizations para campos de texto: `normalizes :email, with: ->(e) { e.strip.downcase }`
- Validações com `uniqueness` escopadas por organização quando necessário:
  ```ruby
  validates :name, uniqueness: { scope: :organization_id }
  ```
- Não criar concerns prematuramente — só extrair quando houver reuso real

## Exemplo

```ruby
class Resource < ApplicationRecord
  belongs_to :organization
  has_many :items, dependent: :destroy

  enum :status, { active: "active", inactive: "inactive" }

  normalizes :name, with: ->(n) { n.strip }

  validates :name, presence: true, length: { minimum: 3, maximum: 50 }
  validates :name, uniqueness: { scope: :organization_id }

  scope :active, -> { where(status: :active) }
end
```

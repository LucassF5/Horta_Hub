---
name: rodar-qualidade
description: "Roda verificações de qualidade do Horta Hub: RSpec, RuboCop e Brakeman. Use para verificar se o código está correto, padronizado e seguro antes de commitar."
argument-hint: "Escopo opcional: 'tudo', 'specs', 'rubocop', 'brakeman', ou path específico"
---

# Verificação de Qualidade

Roda as ferramentas de qualidade do projeto para garantir que o código está correto e padronizado.

## Quando Usar

- Antes de commitar alterações
- Após refatorações
- Para verificar o estado geral do projeto

## Comandos

### Testes (RSpec)

```bash
# Todos os testes
bundle exec rspec

# Testes específicos
bundle exec rspec spec/models/
bundle exec rspec spec/requests/
bundle exec rspec spec/models/product_spec.rb

# Com formato detalhado
bundle exec rspec --format documentation
```

### Linting (RuboCop)

```bash
# Verificar
rubocop

# Corrigir automaticamente
rubocop -a

# Arquivo específico
rubocop app/models/product.rb
```

### Segurança (Brakeman)

```bash
# Scan completo
brakeman

# Sem avisos informativos
brakeman -q
```

## Procedimento Completo

1. Rodar `bundle exec rspec` — todos os testes devem passar
2. Rodar `rubocop -a` — corrigir ofensas de estilo
3. Rodar `brakeman` — verificar vulnerabilidades
4. Se algum falhar, corrigir e repetir

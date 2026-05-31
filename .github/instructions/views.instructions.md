---
description: "Use ao criar ou editar views Phlex e componentes RubyUI. Cobre estrutura de views, helpers, componentes e TailwindCSS."
applyTo: "app/views/**/*.rb"
---

# Padrão de Views (Phlex)

## Estrutura

- Namespace: `Views::NomeDoRecurso::Action`
- Arquivo: `app/views/nome_do_recurso/action.rb`
- Herdam de `Views::Base`
- Método principal: `view_template`
- Seções extraídas para métodos privados `render_*`

## Convenções

- **Nunca usar ERB** — apenas Phlex
- **RubyUI** para componentes visuais: `render RubyUI::Button.new(...)`
- **Helpers Rails**: acessíveis via `helpers.method_name` (ex: `helpers.products_path`)
- **TailwindCSS**: estilização via classes utilitárias inline
- **I18n**: textos visíveis em português
- **Formulários**: usar `form_with` do Phlex::Rails::Helpers

## Componentes RubyUI Disponíveis

Button, Card (Header, Title, Description, Footer), Form, Input, Link, Select, Textarea, Alert, Avatar, Sheet, Sidebar, Typography

## Componentes de Formulário RubyUI

- `RubyUI::FormField` — wrapper de campo
- `RubyUI::FormFieldLabel` — label com `for:`
- `RubyUI::Button` — submit com `type: :submit`
- Classes de input padronizadas via método privado `input_classes`

## Exemplo — View de Listagem

```ruby
class Views::Resources::Index < Views::Base
  def initialize(resources:)
    @resources = resources
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      render_header
      render_resources_list
    end
  end

  private

  def render_header
    div(class: "flex justify-between items-center mb-6") do
      h1(class: "text-3xl font-bold text-gray-900") { "Recursos" }
      render RubyUI::Link.new(href: helpers.new_resource_path, variant: :primary) do
        "Novo Recurso"
      end
    end
  end

  def render_resources_list
    div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6") do
      @resources.each { |resource| render_resource_card(resource) }
    end
  end

  def render_resource_card(resource)
    render RubyUI::Card.new do |card|
      card.header do
        render RubyUI::Card::Title.new { resource.name }
      end
      card.footer do
        render RubyUI::Link.new(href: helpers.resource_path(resource)) { "Ver" }
      end
    end
  end
end
```

## Pattern FormComponent (formulários reutilizáveis)

Para recursos CRUD, criar um `FormComponent` compartilhado entre `new` e `edit`:

```ruby
# app/views/resources/form_component.rb
class Views::Resources::FormComponent < Views::Base
  def initialize(resource:, url:)
    @resource = resource
    @url = url
  end

  def view_template
    form_with(
      model: @resource,
      url: @url,
      local: true,
      class: "bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4 w-full max-w-lg"
    ) do |f|
      render_form_fields(f)
    end
  end

  private

  def render_form_fields(form)
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: "resource_name") { "Nome" }
      form.text_field(:name, id: "resource_name", placeholder: "Nome", class: input_classes)
    end

    div(class: "flex items-center justify-between") do
      render RubyUI::Button.new(type: :submit) { "Salvar" }
    end
  end

  def input_classes
    [
      "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-xs transition-[color,box-shadow] border-border ring-0 ring-ring/0",
      "placeholder:text-muted-foreground",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-ring/50 focus-visible:ring-2 focus-visible:border-ring focus-visible:shadow-sm"
    ].join(" ")
  end
end
```

Nas views `new` e `edit`, renderizar o FormComponent com a URL correta:

```ruby
# new.rb
render Views::Resources::FormComponent.new(resource: @resource, url: helpers.resources_path)

# edit.rb
render Views::Resources::FormComponent.new(resource: @resource, url: helpers.resource_path(@resource))
```

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

## Exemplo — View de Formulário

```ruby
class Views::Resources::New < Views::Base
  def initialize(resource:)
    @resource = resource
  end

  def view_template
    div(class: "container mx-auto px-4 py-8 max-w-lg") do
      h1(class: "text-2xl font-bold mb-6") { "Novo Recurso" }
      render_form
    end
  end

  private

  def render_form
    form_with(model: @resource, class: "space-y-4") do |f|
      render RubyUI::Form::Field.new do
        render RubyUI::Form::Label.new(for: :name) { "Nome" }
        render RubyUI::Input.new(type: :text, name: "resource[name]", id: :name, placeholder: "Nome do recurso")
        render RubyUI::Form::FieldError.new(:name, object: @resource)
      end

      render RubyUI::Button.new(type: :submit, variant: :primary) { "Salvar" }
    end
  end
end
```

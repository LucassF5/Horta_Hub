---
description: "Use ao criar ou editar controllers Rails. Cobre actions RESTful, strong params, escopo por organização e render de views Phlex."
applyTo: "app/controllers/**/*.rb"
---

# Padrão de Controllers

## Estrutura

- RESTful com 7 actions padrão: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
- `before_action :set_resource` para `show`, `edit`, `update`, `destroy`
- Autenticação via concern `Authentication` (já incluído no `ApplicationController`)

## Convenções

- **Escopo obrigatório**: sempre usar `Current.organization.resources` — nunca `Resource.all` ou `Resource.find`
- **Strong params**: usar `params.expect(resource: [:field1, :field2])` (sintaxe Rails 8)
- **Render Phlex**: `render Views::Resource::Action.new(resource: @resource)`
- **Flash messages**: em português
- **Redirects**: após create/update/destroy, redirecionar para index ou show
- **Status codes**: `status: :unprocessable_entity` em renders de erro (create/update falhos)

## Exemplo

```ruby
class ResourcesController < ApplicationController
  before_action :set_resource, only: %i[show edit update destroy]

  def index
    @resources = Current.organization.resources
    render Views::Resources::Index.new(resources: @resources)
  end

  def show
    render Views::Resources::Show.new(resource: @resource)
  end

  def new
    @resource = Current.organization.resources.build
    render Views::Resources::New.new(resource: @resource)
  end

  def create
    @resource = Current.organization.resources.build(resource_params)

    if @resource.save
      redirect_to resources_path, notice: "Recurso criado com sucesso."
    else
      render Views::Resources::New.new(resource: @resource), status: :unprocessable_entity
    end
  end

  def edit
    render Views::Resources::Edit.new(resource: @resource)
  end

  def update
    if @resource.update(resource_params)
      redirect_to resources_path, notice: "Recurso atualizado com sucesso."
    else
      render Views::Resources::Edit.new(resource: @resource), status: :unprocessable_entity
    end
  end

  def destroy
    @resource.destroy
    redirect_to resources_path, notice: "Recurso removido com sucesso."
  end

  private

  def set_resource
    @resource = Current.organization.resources.find(params[:id])
  end

  def resource_params
    params.expect(resource: [:field1, :field2])
  end
end
```

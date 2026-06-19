class ClientsController < ApplicationController
  before_action :set_client, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize!

    @clients = Current.organization.clients.includes(:sales)
    render Views::Clients::Index.new(clients: @clients)
  end

  def show
    authorize! @client
    render Views::Clients::Show.new(client: @client)
  end

  def new
    @client = Current.organization.clients.build
    authorize! @client

    render Views::Clients::New.new(client: @client)
  end

  def create
    @client = Current.organization.clients.build(client_params)
    authorize! @client

    if @client.save
      redirect_to clients_path, notice: "Cliente criado com sucesso!"
    else
      render Views::Clients::New.new(client: @client), status: :unprocessable_entity
    end
  end

  def edit
    authorize! @client
    render Views::Clients::Edit.new(client: @client)
  end

  def update
    authorize! @client

    if @client.update(client_params)
      redirect_to clients_path, notice: "Cliente atualizado com sucesso!"
    else
      render Views::Clients::Edit.new(client: @client), status: :unprocessable_entity
    end
  end

  def destroy
    authorize! @client

    @client.destroy
    redirect_to clients_path, alert: "Client deletado com sucesso!", status: :see_other
  end

  private

  def client_params
    params.expect(client: [ :name, :phone, :client_type ])
  end

  def set_client
    @client = Current.organization.clients.friendly.find(params[:slug])
  end
end

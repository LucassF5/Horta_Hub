class ClientsController < ApplicationController
  before_action :require_authentication
  before_action :set_client, only: [ :show, :edit, :update, :destroy ]

  def index
    @clients = Client.all
    render Views::Clients::Index.new(clients: @clients)
  end

  def show
    render Views::Clients::Show.new(client: @client)
  end

  def new
    @client = Client.new
    render Views::Clients::New.new(client: @client)
  end

  def create
    @client = Client.new(client_params)
    @client.organization = Current.user.organization

    if @client.save
      redirect_to clients_path, notice: "Cliente criado com sucesso!"
    else
      render Views::Clients::New.new(client: @client), status: :unprocessable_entity
    end
  end

  def edit
    render Views::Clients::Edit.new(client: @client)
  end

  def update
    if @client.update(client_params)
      redirect_to clients_path, notice: "Cliente atualizado com sucesso!"
    else
      render Views::Clients::Edit.new(client: @client), status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_path, alert: "Client deletado com sucesso!", status: :see_other
  end

  private

  def client_params
    params.expect(client: [ :name, :phone, :client_type ])
  end

  def set_client
    @client = Client.find(params[:id])
  end
end

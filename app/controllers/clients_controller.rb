class ClientsController < ApplicationController
  before_action :require_authentication
  before_action :set_client, only: [ :show, :edit, :update, :destroy ]

  def index
    @clients = Client.all
  end

  def show
  end

  def new
    @client = Client.new
  end

  def create
    @client = Client.create(client_params)
    if @client.save
      redirect_to clients_path, notice: "Cliente criado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to clients_path, notice: "Cliente atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
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

class ClientsController < ApplicationController
  CLIENT_SORTS = {
    "name" => Listing.case_insensitive(Client.arel_table[:name]),
    "client_type" => Client.arel_table[:client_type]
  }.freeze

  before_action :set_client, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize!

    listing = Listing.new(params, columns: CLIENT_SORTS, default_sort: "name")
    @clients = listing.apply(Current.organization.clients.includes(:sales).search(listing.query)).load
    render Views::Clients::Index.new(clients: @clients, listing: listing)
  end

  def show
    authorize! @client

    # Vendas canceladas aparecem na lista, mas não entram nos totais.
    kept_sales = @client.sales.where.not(status: "cancelled")
    render Views::Clients::Show.new(
      client: @client,
      recent_sales: @client.sales.recent.limit(5),
      sales_count: kept_sales.count,
      total_bought: kept_sales.sum(:total)
    )
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

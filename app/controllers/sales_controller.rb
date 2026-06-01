class SalesController < ApplicationController
  before_action :set_sale, only: %i[show edit update destroy]

  def index
    @sales = Current.organization.sales.includes(:client).recent
    render Views::Sales::Index.new(sales: @sales)
  end

  def show
    render Views::Sales::Show.new(sale: @sale)
  end

  def new
    @sale = Current.organization.sales.build(sale_date: Date.current)
    @sale.sale_items.build
    render Views::Sales::New.new(
      sale: @sale,
      clients: Current.organization.clients,
      products: Current.organization.products
    )
  end

  def create
    @sale = Current.organization.sales.build(sale_params)

    if @sale.save
      redirect_to sales_path, notice: "Venda criada com sucesso."
    else
      render Views::Sales::New.new(
        sale: @sale,
        clients: Current.organization.clients,
        products: Current.organization.products
      ), status: :unprocessable_entity
    end
  end

  def edit
    render Views::Sales::Edit.new(
      sale: @sale,
      clients: Current.organization.clients,
      products: Current.organization.products
    )
  end

  def update
    if @sale.update(sale_params)
      redirect_to sales_path, notice: "Venda atualizada com sucesso."
    else
      render Views::Sales::Edit.new(
        sale: @sale,
        clients: Current.organization.clients,
        products: Current.organization.products
      ), status: :unprocessable_entity
    end
  end

  def destroy
    @sale.destroy
    redirect_to sales_path, notice: "Venda removida com sucesso.", status: :see_other
  end

  private

  def set_sale
    @sale = Current.organization.sales.find(params[:id])
  end

  def sale_params
    params.expect(sale: [
      :client_id, :sale_date, :status, :notes,
      sale_items_attributes: [ [ :id, :product_id, :quantity, :unit_price, :_destroy ] ]
    ])
  end
end

class SalesController < ApplicationController
  before_action :set_sale, only: %i[show edit update destroy]

  def index
    authorize!

    @sales = filter_sales(Current.organization.sales.includes(:client).recent)
    render Views::Sales::Index.new(
      sales: @sales,
      clients: Current.organization.clients.order(:name),
      filters: sales_filter_params
    )
  end

  def show
    authorize! @sale
    render Views::Sales::Show.new(sale: @sale)
  end

  def new
    @sale = Current.organization.sales.build(sale_date: Date.current)
    @sale.sale_items.build
    authorize! @sale

    render Views::Sales::New.new(
      sale: @sale,
      clients: Current.organization.clients,
      products: Current.organization.products
    )
  end

  def create
    @sale = Current.organization.sales.build(sale_params)
    authorize! @sale

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
    authorize! @sale

    render Views::Sales::Edit.new(
      sale: @sale,
      clients: Current.organization.clients,
      products: Current.organization.products
    )
  end

  def update
    authorize! @sale

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
    authorize! @sale

    @sale.destroy
    redirect_to sales_path, notice: "Venda removida com sucesso.", status: :see_other
  end

  def sale_item_fields
    sale = sale_for_item_fields
    authorize! sale, to: sale.persisted? ? :update? : :create?

    item = sale.sale_items.build(quantity: 1)
    component = Views::Sales::SaleItemFieldsComponent.new(
      item: item,
      products: Current.organization.products.order(:name),
      child_index: SecureRandom.random_number(1_000_000_000).to_s
    )

    render turbo_stream: helpers.turbo_stream.append("sale_items", component)
  end

  private

  def set_sale
    @sale = Current.organization.sales.find(params[:id])
  end

  def sale_params
    params.expect(sale: [
      :client_id, :sale_date, :status, :responsible_name, :notes,
      sale_items_attributes: [ [ :id, :product_id, :quantity, :unit_price, :_destroy ] ]
    ])
  end

  def sales_filter_params
    params.permit(:start_date, :end_date, :status, :client_id)
  end

  def filter_sales(scope)
    filters = sales_filter_params

    scope = scope.where(status: filters[:status]) if filters[:status].present? && Sale.statuses.key?(filters[:status])
    scope = scope.where(client_id: filters[:client_id]) if filters[:client_id].present?

    if (start_date = parse_filter_date(filters[:start_date]))
      scope = scope.where(sale_date: start_date..)
    end

    if (end_date = parse_filter_date(filters[:end_date]))
      scope = scope.where(sale_date: ..end_date)
    end

    scope
  end

  def parse_filter_date(value)
    Date.iso8601(value) if value.present?
  rescue Date::Error
    nil
  end

  def sale_for_item_fields
    return Current.organization.sales.find(params[:sale_id]) if params[:sale_id].present?

    Current.organization.sales.build
  end
end

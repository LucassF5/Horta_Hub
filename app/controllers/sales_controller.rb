class SalesController < ApplicationController
  before_action :require_authentication
  before_action :set_sale, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_dependencies, only: [ :new, :edit ]

  def index
    @sales = Sale.includes(:client, :sale_items)
  end

  def new
    @sale = Sale.new
    @sale.sale_items.build
  end

  def show
  end

  def create
    @sale = Current.user.sales.new(sale_params)

    if @sale.save
      redirect_to sales_path, notice: "Sale was successfully created."
    else
      set_form_dependencies
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @sale.update(sale_params)
      redirect_to sales_path, notice: "Sale updated successfully"
    else
      set_form_dependencies
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sale.destroy!
    redirect_to sales_path, alert: "Sale deleted successfully", status: :see_other
  end

  private

  def sale_params
    params.require(:sale).permit(
      :observations,
      :sale_date,
      :client_id,
      sale_items_attributes: [
        :id,
        :product_id,
        :quantity,
        :unit_price,
        :_destroy
      ]
    )
  end

  def set_sale
    @sale = Sale.find(params[:id])
  end

  def set_form_dependencies
    @products = Product.all
    @clients = Client.all
  end
end

class ProductsController < ApplicationController
    before_action :require_authentication
    before_action :set_product, only: [ :show, :edit, :update, :destroy ]

    def index
        @products = Product.all
    end

    def show
    end

    def new
        @product = Product.new
    end

    def create
        @product = Product.new(product_params)

        if @product.save
            redirect_to products_path, notice: "Produto criado com sucesso"
        else
            render :new, status: :unprocessable_entity
        end
    end

    def edit
    end

    def update
        if @product.update(product_params)
            redirect_to products_path, notice: "Produto atualizado com sucesso"
        else
            render :edit, status: :unprocessable_entity
        end
    end

    def destroy
        @product.destroy
        redirect_to products_path, alert: "Produto deletado com sucesso", status: :see_other
    end

    private

    def product_params
        params.expect(product: [ :name, :price ])
    end

    def set_product
        @product = Product.find(params[:id])
    end
end

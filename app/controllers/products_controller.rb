class ProductsController < ApplicationController
    before_action :require_authentication
    before_action :set_product, only: [ :show, :edit, :update, :destroy ]

    def index
        @products = Product.all
        render Views::Products::Index.new(products: @products)
    end

    def show
        render Views::Products::Show.new(product: @product)
    end

    def new
        @product = Product.new
        render Views::Products::New.new(product: @product)
    end

    def create
        @product = Product.new(product_params)
        @product.organization = Current.user.organization

        if @product.save
            redirect_to products_path, notice: "Produto criado com sucesso"
        else
            render Views::Products::New.new(product: @product), status: :unprocessable_entity
        end
    end

    def edit
        render Views::Products::Edit.new(product: @product)
    end

    def update
        if @product.update(product_params)
            redirect_to products_path, notice: "Produto atualizado com sucesso"
        else
            render Views::Products::Edit.new(product: @product), status: :unprocessable_entity
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

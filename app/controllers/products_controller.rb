class ProductsController < ApplicationController
    before_action :set_product, only: [ :show, :edit, :update, :destroy ]

    def index
        authorize!

        @products = Current.organization.products.includes(:sale_items)
        render Views::Products::Index.new(products: @products)
    end

    def show
        authorize! @product
        render Views::Products::Show.new(product: @product)
    end

    def new
        @product = Current.organization.products.build
        authorize! @product

        render Views::Products::New.new(product: @product)
    end

    def create
        @product = Current.organization.products.build(product_params)
        authorize! @product

        if @product.save
            redirect_to products_path, notice: "Produto criado com sucesso"
        else
            render Views::Products::New.new(product: @product), status: :unprocessable_entity
        end
    end

    def edit
        authorize! @product
        render Views::Products::Edit.new(product: @product)
    end

    def update
        authorize! @product

        if @product.update(product_params)
            redirect_to products_path, notice: "Produto atualizado com sucesso"
        else
            render Views::Products::Edit.new(product: @product), status: :unprocessable_entity
        end
    end

    def destroy
        authorize! @product

        @product.destroy
        redirect_to products_path, alert: "Produto deletado com sucesso", status: :see_other
    end

    private

    def product_params
        params.expect(product: [ :name, :price ])
    end

    def set_product
        @product = Current.organization.products.friendly.find(params[:slug])
    end
end

class ProductsController < ApplicationController
    PRODUCT_SORTS = {
        "name" => Listing.case_insensitive(Product.arel_table[:name]),
        "price" => Product.arel_table[:price]
    }.freeze

    before_action :set_product, only: [ :show, :edit, :update, :destroy ]

    def index
        authorize!

        listing = Listing.new(params, columns: PRODUCT_SORTS, default_sort: "name")
        @products = listing.apply(Current.organization.products.includes(:sale_items).search(listing.query)).load
        render Views::Products::Index.new(products: @products, listing: listing)
    end

    def show
        authorize! @product

        # Vendas canceladas aparecem na lista, mas não contam como vendidas.
        sold_items = @product.sale_items.joins(:sale).where.not(sales: { status: "cancelled" })
        render Views::Products::Show.new(
            product: @product,
            recent_items: @product.sale_items.includes(sale: :client).joins(:sale).merge(Sale.recent).limit(5),
            sales_count: sold_items.distinct.count(:sale_id),
            units_sold: sold_items.sum(:quantity)
        )
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

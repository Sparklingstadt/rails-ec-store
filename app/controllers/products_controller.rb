class ProductsController < ApplicationController
  def index
    @search = ProductSearch.new(params)
    @category, @query, @sort = @search.category, @search.query, @search.sort
    @products = @search.products
    @show_hero = request.path == root_path && !@search.filtered? && @search.page == 1
  end

  def show
    @product = Product.published.find_by!(slug: params[:slug])
    @related_products = Product.published.where.not(id: @product.id).order(:position).limit(3)
  end
end

class ProductsController < ApplicationController
  def index
    @category = params[:category].presence_in(Product::CATEGORIES.keys)
    @query = params[:q].to_s.strip.first(100)
    @sort = params[:sort].presence_in(Product::SORTS.keys) || "recommended"
    @products = Product.published.search(@query)
    @products = @products.where(category: @category) if @category
    @products = @products.where(featured: true) if params[:collection] == "new"
    @products = @products.order(Product::SORTS.fetch(@sort))
    @show_hero = request.path == root_path && @query.blank? && @category.nil? && params[:collection].blank?
  end

  def show
    @product = Product.published.find_by!(slug: params[:slug])
    @related_products = Product.published.where.not(id: @product.id).order(:position).limit(3)
  end
end

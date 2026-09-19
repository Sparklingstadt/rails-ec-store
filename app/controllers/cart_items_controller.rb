class CartItemsController < ApplicationController
  rescue_from Cart::InvalidQuantity, with: :invalid_quantity

  def create
    product = Product.find(params[:product_id])
    current_cart.add(product, params[:quantity] || 1)
    save_cart
    redirect_to cart_path, notice: "#{product.name}をカートに追加しました。", status: :see_other
  end

  def update
    product = Product.find(params[:id])
    current_cart.set(product, params[:quantity])
    save_cart
    redirect_to cart_path, notice: "数量を変更しました。", status: :see_other
  end

  def destroy
    current_cart.remove(params[:id])
    save_cart
    redirect_to cart_path, notice: "商品をカートから削除しました。", status: :see_other
  end

  private

  def invalid_quantity(error)
    redirect_to cart_path, alert: error.message, status: :see_other
  end
end

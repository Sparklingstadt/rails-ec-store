class ApplicationController < ActionController::Base
  include Authentication
  helper_method :current_cart, :favorite_ids

  private

  def current_cart
    @current_cart ||= Cart.new(current_user ? current_user.cart_data.deep_dup : session[:cart])
  end

  def favorite_ids
    current_user ? current_user.saved_product_ids : (session[:favorites] ||= [])
  end

  def buyer_key
    session[:buyer_key] ||= SecureRandom.hex(32)
  end

  def save_cart
    persist_cart(current_cart.data)
    session[:checkout_key] = nil
  end

  def persist_cart(data)
    current_user ? current_user.update!(cart_data: data) : session[:cart] = data
    @current_cart = nil
  end

  def save_favorites(ids)
    current_user ? current_user.update!(saved_product_ids: ids) : session[:favorites] = ids
  end

  def accessible_orders
    current_user ? current_user.orders : Order.where(user_id: nil, buyer_key: buyer_key)
  end
end

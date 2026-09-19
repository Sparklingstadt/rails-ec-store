class ApplicationController < ActionController::Base
  helper_method :current_cart, :favorite_ids

  private

  def current_cart
    @current_cart ||= Cart.new(session[:cart])
  end

  def favorite_ids
    session[:favorites] ||= []
  end

  def buyer_key
    session[:buyer_key] ||= SecureRandom.hex(32)
  end

  def save_cart
    session[:cart] = current_cart.data
    session[:checkout_key] = nil
  end
end

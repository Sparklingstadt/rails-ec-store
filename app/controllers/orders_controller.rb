class OrdersController < ApplicationController
  before_action :disable_cache

  def index
    @orders = accessible_orders.includes(:order_items).order(created_at: :desc).limit(30)
  end

  def new
    return redirect_to cart_path, alert: "カートに商品を追加してください。" if current_cart.empty?
    session[:checkout_key] ||= SecureRandom.uuid
    @order = Order.new(current_user&.shipping_attributes || {})
  end

  def create
    unless session[:checkout_key].present? && ActiveSupport::SecurityUtils.secure_compare(session[:checkout_key], params[:checkout_key].to_s)
      return redirect_to cart_path, alert: "カートが更新されました。もう一度ご注文手続きにお進みください。", status: :see_other
    end
    @order = PlaceOrder.call(cart: current_cart, attributes: order_params.to_h, buyer_key: buyer_key, checkout_key: session[:checkout_key], user: current_user)
    persist_cart({})
    redirect_to order_path(@order), notice: "デモ注文を受け付けました。", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    @order = error.record
    render :new, status: :unprocessable_entity
  rescue PlaceOrder::Unavailable => error
    redirect_to cart_path, alert: error.message, status: :see_other
  end

  def show
    @order = accessible_orders.includes(:order_items).find_by!(number: params[:number])
  end

  private

  def order_params
    params.require(:order).permit(:name, :email, :postal_code, :prefecture, :address)
  end

  def disable_cache
    response.headers["Cache-Control"] = "no-store"
  end
end

module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [ :show, :update ]

    def index
      @status = params[:status].presence_in(Order::STATUSES.keys)
      @orders = Order.includes(:order_items).order(created_at: :desc)
      @orders = @orders.where(status: @status) if @status
      @orders = @orders.limit(100)
    end

    def show
    end

    def update
      ChangeOrderStatus.call(order: @order, to: params[:status].to_s)
      redirect_to admin_order_path(@order), notice: "注文状態を更新しました。", status: :see_other
    rescue ChangeOrderStatus::InvalidTransition => error
      redirect_to admin_order_path(@order), alert: error.message, status: :see_other
    end

    private

    def set_order
      @order = Order.includes(:order_items).find_by!(number: params[:number])
    end
  end
end

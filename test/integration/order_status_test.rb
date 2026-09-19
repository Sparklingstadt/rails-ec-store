require "test_helper"

class OrderStatusTest < ActionDispatch::IntegrationTest
  setup do
    SessionsController::RATE_LIMIT_STORE.clear
    @product = products(:mug)
    @stock = @product.stock
    @order = PlaceOrder.call(cart: Cart.new({ @product.id.to_s => 2 }), attributes: { name: "テスト", email: "test@example.com", postal_code: "1000001", prefecture: "東京都", address: "サンプル町" }, buyer_key: SecureRandom.hex(16), checkout_key: SecureRandom.uuid, user: users(:member))
  end

  def login(user)
    post session_path, params: { email: user.email, password: "sample-password-123" }
  end

  test "owner cancels and repeated requests restore inventory only once" do
    login(users(:member))
    2.times { post cancel_order_path(@order) }
    assert_redirected_to order_path(@order)
    assert_equal "cancelled", @order.reload.status
    assert_not_nil @order.cancelled_at
    assert_equal @stock, @product.reload.stock
    get order_path(@order)
    assert_select "form[action=?]", cancel_order_path(@order), count: 0
  end

  test "other members and guests cannot cancel another buyer's order" do
    post cancel_order_path(@order)
    assert_response :not_found
    login(users(:other))
    post cancel_order_path(@order)
    assert_response :not_found
    assert_equal "placed", @order.reload.status
    assert_equal @stock - 2, @product.reload.stock
    patch admin_order_path(@order), params: { status: "shipped" }
    assert_response :forbidden
  end

  test "administrator ships and shipped order cannot be cancelled" do
    login(users(:admin))
    patch admin_order_path(@order), params: { status: "shipped" }
    assert_redirected_to admin_order_path(@order)
    assert_equal "shipped", @order.reload.status
    assert_not_nil @order.shipped_at
    patch admin_order_path(@order), params: { status: "cancelled" }
    assert_equal "shipped", @order.reload.status
    delete session_path
    login(users(:member))
    post cancel_order_path(@order)
    assert_equal "shipped", @order.reload.status
    assert_equal @stock - 2, @product.reload.stock
  end

  test "administrator cancels hidden products and invalid transitions are rejected" do
    @product.reload.update!(published: false)
    login(users(:admin))
    patch admin_order_path(@order), params: { status: "unknown" }
    assert_equal "placed", @order.reload.status
    patch admin_order_path(@order), params: { status: "cancelled" }
    assert_equal "cancelled", @order.reload.status
    assert_equal @stock, @product.reload.stock
    patch admin_order_path(@order), params: { status: "shipped" }
    assert_equal "cancelled", @order.reload.status
    get admin_orders_path(status: "cancelled")
    assert_response :success
    assert_select "a[href=?]", admin_order_path(@order)
  end
end

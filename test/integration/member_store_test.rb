require "test_helper"

class MemberStoreTest < ActionDispatch::IntegrationTest
  setup do
    SessionsController::RATE_LIMIT_STORE.clear
    @address = { name: "会員サンプル", email: "demo@example.com", postal_code: "100-0001", prefecture: "東京都", address: "サンプル町1-2-3" }
  end

  def login(user = users(:member))
    post session_path, params: { email: user.email, password: "sample-password-123" }
    assert_redirected_to account_path
  end

  def order_mug
    post cart_items_path, params: { product_id: products(:mug).id, quantity: 1 }
    get new_order_path
    key = css_select("input[name=checkout_key]").first["value"]
    post orders_path, params: { checkout_key: key, order: @address }
    Order.last
  end

  test "guest cart and favorites merge once and persist across browser sessions" do
    users(:member).update!(cart_data: { products(:mug).id.to_s => 1 })
    post cart_items_path, params: { product_id: products(:mug).id, quantity: 2 }
    post favorites_path, params: { product_id: products(:vase).id }
    login
    assert_equal 3, users(:member).reload.cart_data[products(:mug).id.to_s]
    assert_includes users(:member).saved_product_ids, products(:vase).id
    delete session_path
    get cart_path
    assert_select ".empty-state"
    get favorites_path
    assert_select ".empty-state"
    login
    get cart_path
    assert_select "input[type=number][value='3']"
    assert_equal 3, users(:member).reload.cart_data[products(:mug).id.to_s]
    get favorites_path
    assert_select ".product-card", count: 1
  end

  test "same browser guest orders are claimed and another member cannot view them" do
    order = order_mug
    assert_nil order.user_id
    login
    assert_equal users(:member), order.reload.user
    delete session_path
    get order_path(order)
    assert_response :not_found
    login(users(:other))
    get order_path(order)
    assert_response :not_found
    get orders_path
    assert_select ".history-row", count: 0
  end

  test "member orders survive logout and a fresh login" do
    login
    order = order_mug
    assert_equal users(:member), order.user
    assert_empty users(:member).reload.cart_data
    delete session_path
    login
    get order_path(order)
    assert_response :success
  end

  test "saved address prefills checkout but cannot change email or role" do
    login
    patch account_path, params: { user: @address.merge(admin: true, email: "changed@example.com") }
    assert_redirected_to account_path
    user = users(:member).reload
    assert_not user.admin?
    assert_equal "member@example.com", user.email
    assert_equal "1000001", user.postal_code
    post cart_items_path, params: { product_id: products(:mug).id, quantity: 1 }
    get new_order_path
    assert_select "input[name='order[postal_code]'][value='1000001']"
    assert_select "input[name='order[name]'][value='会員サンプル']"
  end

  test "partial address is rejected without changing saved profile" do
    login
    patch account_path, params: { user: { postal_code: "123" } }
    assert_response :unprocessable_entity
    assert_select ".form-errors"
    assert_nil users(:member).reload.postal_code
  end

  test "member cart updates and favorite removal write to database" do
    login
    post cart_items_path, params: { product_id: products(:mug).id, quantity: 1 }
    patch cart_item_path(products(:mug).id), params: { quantity: 2 }
    assert_equal 2, users(:member).reload.cart_data[products(:mug).id.to_s]
    delete cart_item_path(products(:mug).id)
    assert_empty users(:member).reload.cart_data
    post favorites_path, params: { product_id: products(:mug).id }
    delete favorite_path(products(:mug).id)
    assert_empty users(:member).reload.saved_product_ids
  end
end

require "test_helper"

class StoreFlowTest < ActionDispatch::IntegrationTest
  setup do
    @attributes = { name: "余白 花子", email: "demo@example.com", postal_code: "100-0001", prefecture: "東京都", address: "サンプル町1-2-3" }
  end

  def prepare_checkout
    post cart_items_path, params: { product_id: products(:mug).id, quantity: 2 }
    get new_order_path
    assert_response :success
    css_select("input[name=checkout_key]").first["value"]
  end

  test "browse filter search sort and product details" do
    get root_path
    assert_response :success
    assert_select ".hero", count: 1
    assert_select ".product-card", count: 2
    get products_path, params: { category: "interior" }
    assert_select ".product-card", count: 1
    assert_select ".product-card h3", text: "一輪挿し しずく"
    get products_path, params: { q: "マグ" }
    assert_select ".product-card", count: 1
    get products_path, params: { q: "%" }
    assert_select ".empty-state", count: 1
    get products_path, params: { sort: "price_desc" }
    assert_equal "一輪挿し しずく", css_select(".product-card h3").first.text.strip
    get products_path, params: { collection: "new" }
    assert_select ".product-card", count: 1
    get product_path(products(:mug))
    assert_response :success
    assert_select "button", text: /カートに入れる/
  end

  test "cart updates persists and removes items" do
    post cart_items_path, params: { product_id: products(:mug).id, quantity: 1 }
    assert_redirected_to cart_path
    get cart_path
    assert_select ".cart-item", count: 1
    patch cart_item_path(products(:mug).id), params: { quantity: 3 }
    follow_redirect!
    assert_select ".summary-total strong", text: "¥7,750"
    delete cart_item_path(products(:mug).id)
    follow_redirect!
    assert_select ".empty-state", count: 1
  end

  test "invalid cart quantity rejected without losing items" do
    post cart_items_path, params: { product_id: products(:mug).id, quantity: 1 }
    patch cart_item_path(products(:mug).id), params: { quantity: -2 }
    follow_redirect!
    assert_select "[role=alert]"
    assert_select "input[type=number][value='1']"
  end

  test "favorites can be added and removed" do
    post favorites_path, params: { product_id: products(:mug).id }
    get favorites_path
    assert_select ".product-card", count: 1
    delete favorite_path(products(:mug).id)
    get favorites_path
    assert_select ".empty-state", count: 1
  end

  test "checkout creates order ignores client prices and clears cart" do
    key = prepare_checkout
    assert_difference "Order.count", 1 do
      post orders_path, params: { checkout_key: key, order: @attributes.merge(total: 1, shipping: 0, buyer_key: "attacker") }
    end
    order = Order.last
    assert_equal 5350, order.total
    assert_not_equal "attacker", order.buyer_key
    assert_equal 8, products(:mug).reload.stock
    assert_redirected_to order_path(order)
    follow_redirect!
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_select ".cart-count", text: "0"
    get orders_path
    assert_select ".history-row", count: 1
    assert_no_difference "Order.count" do
      post orders_path, params: { checkout_key: key, order: @attributes }
    end
  end

  test "another browser cannot access the order by its URL" do
    key = prepare_checkout
    post orders_path, params: { checkout_key: key, order: @attributes }
    order = Order.last
    other = open_session
    other.get order_path(order)
    other.assert_response :not_found
    other.get orders_path
    other.assert_select ".history-row", count: 0
  end

  test "validation errors are Japanese and preserve the cart" do
    key = prepare_checkout
    assert_no_difference "Order.count" do
      post orders_path, params: { checkout_key: key, order: @attributes.merge(name: "", email: "invalid", postal_code: "1") }
    end
    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /お名前を入力してください/
    assert_select ".cart-count", text: "2"
  end

  test "changed cart invalidates previously opened checkout form" do
    key = prepare_checkout
    patch cart_item_path(products(:mug).id), params: { quantity: 1 }
    assert_no_difference "Order.count" do
      post orders_path, params: { checkout_key: key, order: @attributes }
    end
    assert_redirected_to cart_path
  end

  test "out of stock product cannot be purchased" do
    products(:mug).update!(stock: 0)
    get product_path(products(:mug))
    assert_select ".sold-out-message"
    assert_select ".add-cart-form", count: 0
    post cart_items_path, params: { product_id: products(:mug).id, quantity: 1 }
    follow_redirect!
    assert_select "[role=alert]", text: /在庫は0点/
  end

  test "empty checkout and invalid token never create orders" do
    get new_order_path
    assert_redirected_to cart_path
    assert_no_difference "Order.count" do
      post orders_path, params: { checkout_key: "fake", order: @attributes }
    end
    assert_redirected_to cart_path
  end

  test "information pages render and missing products return 404" do
    [ about_path, guide_path, favorites_path, orders_path ].each do |path|
      get path
      assert_response :success
    end
    get product_path("missing")
    assert_response :not_found
  end
end

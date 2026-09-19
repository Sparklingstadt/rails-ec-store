require "test_helper"

class AdminProductsTest < ActionDispatch::IntegrationTest
  setup do
    SessionsController::RATE_LIMIT_STORE.clear
    @attributes = products(:mug).attributes.except("id", "created_at", "updated_at", "lock_version").merge("slug" => "new-mug", "name" => "新しいマグ", "published" => false)
  end

  def login(user)
    post session_path, params: { email: user.email, password: "sample-password-123" }
  end

  test "guests and members cannot access admin or write products" do
    get admin_products_path
    assert_redirected_to new_session_path
    login(users(:member))
    get admin_products_path
    assert_response :forbidden
    assert_no_difference "Product.count" do
      post admin_products_path, params: { product: @attributes }
    end
    assert_response :forbidden
    patch admin_product_path(products(:mug)), params: { product: { stock: 999 } }
    assert_response :forbidden
    assert_equal 10, products(:mug).reload.stock
  end

  test "admin creates and publishes a product" do
    login(users(:admin))
    get new_admin_product_path
    assert_response :success
    assert_difference "Product.count", 1 do
      post admin_products_path, params: { product: @attributes }
    end
    assert_redirected_to admin_products_path
    product = Product.find_by!(slug: "new-mug")
    get product_path(product)
    assert_response :not_found
    get edit_admin_product_path(product)
    assert_response :success
    patch admin_product_path(product), params: { product: { published: true, price: 3100, lock_version: product.lock_version } }
    assert_redirected_to admin_products_path
    get product_path(product)
    assert_response :success
    assert_select ".detail-price", text: /3,100/
  end

  test "invalid stock and unsafe image filename are rejected" do
    login(users(:admin))
    patch admin_product_path(products(:mug)), params: { product: { stock: -1, image: "../../secret" } }
    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /在庫/
    assert_equal 10, products(:mug).reload.stock
    assert_equal "mug.png", products(:mug).image
  end

  test "stale stock form cannot overwrite intervening purchase" do
    login(users(:admin))
    product = products(:mug)
    previous = product.lock_version
    PlaceOrder.call(cart: Cart.new({ product.id.to_s => 1 }), attributes: { name: "サンプル", email: "sample@example.com", postal_code: "1000001", prefecture: "東京都", address: "サンプル町" }, buyer_key: "admin-test", checkout_key: SecureRandom.uuid)
    patch admin_product_path(product), params: { product: { stock: 50, lock_version: previous } }
    assert_response :conflict
    assert_equal 9, product.reload.stock
  end

  test "unpublished products disappear from catalog favorites cart and direct purchase" do
    post favorites_path, params: { product_id: products(:mug).id }
    post cart_items_path, params: { product_id: products(:mug).id, quantity: 1 }
    products(:mug).update!(published: false)
    get products_path
    assert_select ".product-card", count: 1
    get favorites_path
    assert_select ".product-card", count: 0
    get cart_path
    assert_select ".cart-item", count: 0
    get product_path(products(:mug))
    assert_response :not_found
    post cart_items_path, params: { product_id: products(:mug).id, quantity: 1 }
    assert_response :not_found
  end
end

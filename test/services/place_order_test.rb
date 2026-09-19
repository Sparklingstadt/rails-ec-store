require "test_helper"

class PlaceOrderTest < ActiveSupport::TestCase
  setup do
    @attributes = { name: "テスト 花子", email: "DEMO@example.com ", postal_code: "１００-０００１", prefecture: "東京都", address: "サンプル町1-2-3" }
    @cart = Cart.new({ products(:mug).id.to_s => 2 })
    @key = SecureRandom.uuid
  end

  def purchase(cart = @cart, attributes = @attributes, key = @key)
    PlaceOrder.call(cart: cart, attributes: attributes, buyer_key: "test-buyer", checkout_key: key)
  end

  test "stores price and name snapshots and decrements stock" do
    order = purchase
    assert_equal 4800, order.subtotal
    assert_equal 5350, order.total
    assert_equal 8, products(:mug).reload.stock
    assert_equal "demo@example.com", order.email
    assert_equal "1000001", order.postal_code
    products(:mug).update!(price: 3000, name: "変更後の名称")
    assert_equal 2400, order.order_items.first.unit_price
    assert_equal "日々のマグカップ", order.order_items.first.name
  end

  test "repeated submission creates only one order and decrements stock once" do
    first = purchase
    assert_no_difference [ "Order.count", "OrderItem.count" ] do
      assert_equal first, purchase(Cart.new({}))
    end
    assert_equal 8, products(:mug).reload.stock
  end

  test "insufficient stock rolls back all order items and stock changes" do
    cart = Cart.new({ products(:mug).id.to_s => 1, products(:vase).id.to_s => 3 })
    assert_no_difference [ "Order.count", "OrderItem.count" ] do
      assert_raises(PlaceOrder::Unavailable) { purchase(cart) }
    end
    assert_equal 10, products(:mug).reload.stock
    assert_equal 2, products(:vase).reload.stock
  end

  test "invalid contact details cannot create an order or change stock" do
    assert_no_difference "Order.count" do
      assert_raises(ActiveRecord::RecordInvalid) { purchase(@cart, @attributes.merge(email: "invalid", postal_code: "12")) }
    end
    assert_equal 10, products(:mug).reload.stock
  end

  test "rechecks current stock and price at checkout" do
    @cart.items
    products(:mug).update!(price: 2900)
    assert_equal 5800, purchase.subtotal
    products(:mug).update!(stock: 0)
    assert_raises(PlaceOrder::Unavailable) { purchase(@cart, @attributes, SecureRandom.uuid) }
  end

  test "empty cart cannot be ordered" do
    assert_raises(PlaceOrder::Unavailable) { purchase(Cart.new({})) }
  end

  test "free shipping starts at the exact threshold" do
    products(:mug).update!(price: 4000)
    order = purchase
    assert_equal 8000, order.total
    assert_equal 0, order.shipping
  end

  test "database constraint prevents negative inventory" do
    assert_raises(ActiveRecord::StatementInvalid) { products(:mug).update_columns(stock: -1) }
  end
end

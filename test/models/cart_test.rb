require "test_helper"

class CartTest < ActiveSupport::TestCase
  test "calculates prices from database and applies shipping threshold" do
    cart = Cart.new({})
    cart.add(products(:mug), "3")
    assert_equal 7200, cart.subtotal
    assert_equal 550, cart.shipping
    cart.add(products(:mug), "1")
    assert_equal 9600, cart.total
    assert_equal 0, cart.shipping
  end

  test "rejects zero negative fractional excessive and nonnumeric quantities" do
    %w[0 -1 1.5 21 abc 1abc].each do |quantity|
      assert_raises(Cart::InvalidQuantity) { Cart.new({}).add(products(:mug), quantity) }
    end
  end

  test "enforces stock including items already in cart" do
    cart = Cart.new({ products(:vase).id.to_s => 2 })
    assert_raises(Cart::InvalidQuantity) { cart.add(products(:vase), 1) }
    assert_equal 2, cart.count
  end

  test "empty and removed products have no shipping charge" do
    cart = Cart.new({ "999999999" => 3 })
    assert cart.empty?
    assert_equal 0, cart.total
    cart.add(products(:mug), 1)
    cart.remove(products(:mug).id)
    assert cart.empty?
  end
end

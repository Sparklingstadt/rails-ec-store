require "test_helper"

class ConcurrentOrdersTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  self.fixture_table_names = []

  setup do
    @buyer = SecureRandom.hex(16)
    @product = Product.create!(slug: "concurrency-#{@buyer}", name: "同時注文テスト", english_name: "Concurrent item", category: "tableware", image: "mug.png", description: "テスト専用", material: "陶器", size: "300ml", color: "白", price: 2400, stock: 1)
    @attributes = { name: "テスト", email: "test@example.com", postal_code: "1000001", prefecture: "東京都", address: "サンプル町" }
  end

  teardown do
    Order.where(buyer_key: @buyer).destroy_all
    @product.destroy!
  end

  def race(keys)
    ready = Queue.new
    start = Queue.new
    threads = keys.map do |key|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          PlaceOrder.call(cart: Cart.new({ @product.id.to_s => 1 }), attributes: @attributes, buyer_key: @buyer, checkout_key: key)
        rescue PlaceOrder::Unavailable
          :sold_out
        end
      end
    end
    keys.size.times { ready.pop }
    keys.size.times { start << true }
    threads.map(&:value)
  end

  test "two simultaneous buyers cannot buy the last item twice" do
    results = race([ SecureRandom.uuid, SecureRandom.uuid ])
    assert_equal 1, results.count { |result| result.is_a?(Order) }
    assert_equal 1, results.count(:sold_out)
    assert_equal 0, @product.reload.stock
    assert_equal 1, Order.where(buyer_key: @buyer).count
  end

  test "simultaneous duplicate submits return one order" do
    key = SecureRandom.uuid
    results = race([ key, key ])
    assert results.all? { |result| result.is_a?(Order) }
    assert_equal 1, results.map(&:id).uniq.size
    assert_equal 1, Order.where(buyer_key: @buyer).count
    assert_equal 0, @product.reload.stock
  end
end

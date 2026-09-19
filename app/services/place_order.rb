# 注文、明細、在庫を同一トランザクションで保存する。
class PlaceOrder
  class Unavailable < StandardError; end

  def self.call(cart:, attributes:, buyer_key:, checkout_key:, user: nil)
    existing = Order.find_by(buyer_key: buyer_key, checkout_key: checkout_key)
    return existing if existing
    raise Unavailable, "カートに商品がありません。" if cart.empty?

    Order.transaction do
      # 最初に注文を書き込み、SQLiteの書き込みロックを取る。
      order = Order.create!(attributes.merge(buyer_key: buyer_key, checkout_key: checkout_key, user: user))
      cart.data.sort.each do |id, quantity|
        product = Product.published.find_by(id: id)
        raise Unavailable, "商品が見つかりません。カートをご確認ください。" unless product

        # 条件付きUPDATEで、同時注文でも在庫がマイナスになるのを防ぐ。
        updated = Product.published.where(id: id).where("stock >= ?", quantity).update_all([ "stock = stock - ?, lock_version = lock_version + 1, updated_at = ?", quantity, Time.current ])
        raise Unavailable, "#{product.name}の在庫が不足しています。カートの数量を変更してください。" if updated.zero?
        order.order_items.create!(product: product, name: product.name, image: product.image, unit_price: product.price, quantity: quantity)
      end
      subtotal = order.order_items.sum { |item| item.total }
      shipping = subtotal >= Cart::FREE_SHIPPING_THRESHOLD ? 0 : Cart::SHIPPING_FEE
      order.update!(subtotal: subtotal, shipping: shipping, total: subtotal + shipping)
      order
    end
  rescue ActiveRecord::RecordNotUnique
    # 同じフォームの二重送信は、すでに作成された注文を返す。
    Order.find_by!(buyer_key: buyer_key, checkout_key: checkout_key)
  end
end

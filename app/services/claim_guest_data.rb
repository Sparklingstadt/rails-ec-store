# このブラウザが所有する未紐付けのゲスト注文だけを、ログインした会員へ移す。
class ClaimGuestData
  def self.call(user:, cart_data:, favorite_ids:, buyer_key:)
    user.with_lock do
      cart = Cart.new(user.cart_data)
      merged = cart.data.merge(Cart.new(cart_data).data) { |_id, saved, guest| [ saved + guest, Cart::MAX_QUANTITY ].min }
      user.update!(cart_data: merged, saved_product_ids: (user.saved_product_ids + Array(favorite_ids)).uniq.last(50))
      if buyer_key.present?
        Order.where(user_id: nil, buyer_key: buyer_key).update_all(user_id: user.id)
      end
    end
  end
end

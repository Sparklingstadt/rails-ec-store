class ChangeOrderStatus
  class InvalidTransition < StandardError; end

  def self.call(order:, to:)
    raise InvalidTransition, "注文状態が正しくありません。" unless %w[shipped cancelled].include?(to)

    order.with_lock do
      # 再送信で在庫を重複して戻さない。
      return order if order.status == to
      raise InvalidTransition, "受付済みの注文のみ変更できます。最新の注文状態をご確認ください。" unless order.status == "placed"

      if to == "cancelled"
        order.order_items.order(:product_id).each do |item|
          Product.where(id: item.product_id).update_all([ "stock = stock + ?, lock_version = lock_version + 1, updated_at = ?", item.quantity, Time.current ])
        end
        order.update!(status: to, cancelled_at: Time.current)
      else
        order.update!(status: to, shipped_at: Time.current)
      end
    end
    order
  end
end

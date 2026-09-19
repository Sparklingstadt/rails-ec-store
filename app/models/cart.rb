# Cookie sessionにはIDと数量だけを保存。金額は常にDBの商品から計算する。
class Cart
  MAX_QUANTITY = 20
  FREE_SHIPPING_THRESHOLD = 8_000
  SHIPPING_FEE = 550
  class InvalidQuantity < StandardError; end

  Item = Data.define(:product, :quantity) do
    def total = product.price * quantity
  end

  def initialize(data)
    @data = data || {}
  end

  def items
    @items ||= Product.published.where(id: @data.keys).order(:position, :id).map do |product|
      Item.new(product: product, quantity: @data.fetch(product.id.to_s).to_i.clamp(1, MAX_QUANTITY))
    end
  end

  def data = items.to_h { |item| [ item.product.id.to_s, item.quantity ] }
  def count = items.sum(&:quantity)
  def empty? = items.empty?
  def subtotal = items.sum(&:total)
  def shipping = empty? || subtotal >= FREE_SHIPPING_THRESHOLD ? 0 : SHIPPING_FEE
  def total = subtotal + shipping

  def add(product, quantity)
    quantity = parse_quantity(quantity)
    set(product, @data.fetch(product.id.to_s, 0).to_i + quantity)
  end

  def set(product, quantity)
    quantity = parse_quantity(quantity)
    raise InvalidQuantity, "#{product.name}の在庫は#{product.stock}点です。" if quantity > product.stock
    @data[product.id.to_s] = quantity
    @items = nil
  end

  def remove(id)
    @data.delete(id.to_s)
    @items = nil
  end

  private

  def parse_quantity(value)
    quantity = Integer(value.to_s, 10, exception: false)
    raise InvalidQuantity, "数量は1〜#{MAX_QUANTITY}点で指定してください。" unless quantity && (1..MAX_QUANTITY).cover?(quantity)
    quantity
  end
end

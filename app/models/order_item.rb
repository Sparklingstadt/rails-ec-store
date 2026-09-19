class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  validates :name, :image, presence: true
  validates :quantity, numericality: { only_integer: true, in: 1..Cart::MAX_QUANTITY }
  validates :unit_price, numericality: { only_integer: true, greater_than: 0 }
  def total = unit_price * quantity
end

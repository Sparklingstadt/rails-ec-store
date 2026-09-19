class Product < ApplicationRecord
  CATEGORIES = { "tableware" => "うつわ", "interior" => "インテリア", "textile" => "布もの", "fragrance" => "香り" }.freeze
  IMAGES = { "mug.png" => "マグカップ", "vase.png" => "花瓶", "linen.png" => "リネン", "tray.png" => "トレイ", "candle.png" => "キャンドル", "dripper.png" => "ドリッパー" }.freeze
  SORTS = { "recommended" => { position: :asc, id: :asc }, "price_asc" => { price: :asc, id: :asc }, "price_desc" => { price: :desc, id: :asc }, "newest" => { created_at: :desc, id: :desc } }.freeze

  has_many :order_items, dependent: :restrict_with_error
  validates :slug, :name, :english_name, :image, :description, :material, :size, :color, presence: true
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :category, inclusion: { in: CATEGORIES.keys }
  validates :price, numericality: { only_integer: true, greater_than: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :image, inclusion: { in: IMAGES.keys }
  validates :name, :english_name, :slug, length: { maximum: 120 }
  validates :description, length: { maximum: 5000 }
  scope :published, -> { where(published: true) }

  scope :search, ->(query) {
    where("name LIKE :q OR english_name LIKE :q OR description LIKE :q", q: "%#{sanitize_sql_like(query.to_s.strip)}%") if query.present?
  }

  def to_param = slug
  def category_name = CATEGORIES.fetch(category)
  def available? = stock.positive?
end

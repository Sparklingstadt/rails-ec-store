class User < ApplicationRecord
  has_secure_password
  has_many :login_sessions, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }
  validates :name, presence: true, length: { maximum: 80 }
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }
  validates :password, length: { minimum: 12, maximum: 72 }, if: -> { password.present? }
  normalizes :postal_code, with: ->(value) { value.tr("０-９", "0-9").delete("-ー ") }
  validates :postal_code, format: { with: /\A\d{7}\z/ }, if: :address_started?
  validates :prefecture, inclusion: { in: Order::PREFECTURES }, if: :address_started?
  validates :address, presence: true, length: { maximum: 250 }, if: :address_started?

  def shipping_attributes
    attributes.slice("name", "email", "postal_code", "prefecture", "address")
  end

  def address_started?
    [ postal_code, prefecture, address ].any?(&:present?)
  end
end

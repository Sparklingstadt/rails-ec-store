class User < ApplicationRecord
  has_secure_password
  has_many :login_sessions, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }
  validates :name, presence: true, length: { maximum: 80 }
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }
  validates :password, length: { minimum: 12, maximum: 72 }, if: -> { password.present? }
end

class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, {
    user: "user",
    admin: "admin"
  }

  validates :username, presence: true, length: { minimum: 3, maximum: 30 }
  validates :email_address, presence: true, uniqueness: true
end

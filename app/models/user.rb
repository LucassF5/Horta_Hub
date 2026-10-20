class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :import_batches, dependent: :destroy
  # Sem dependent: o before_destroy keep_seller_name_on_sold_sales cuida das vendas.
  has_many :sold_sales, class_name: "Sale", foreign_key: :seller_id, inverse_of: :seller

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :username, presence: true, length: { minimum: 3, maximum: 30 }
  validates :email_address, presence: true, uniqueness: true

  before_destroy :keep_seller_name_on_sold_sales

  def self.generate_password
    SecureRandom.alphanumeric(8)
  end

  def membership_for(organization)
    return if organization.blank?

    memberships.find_by(organization: organization)
  end

  def reset_password!
    password = self.class.generate_password

    transaction do
      update!(password: password, password_confirmation: password)
      sessions.destroy_all
    end

    password
  end

  def member_of_active_organization?
    organizations.active.exists?
  end

  private

  def keep_seller_name_on_sold_sales
    sold_sales.update_all(seller_id: nil, responsible_name: username, updated_at: Time.current)
  end
end

# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email_address   :string           not null
#  password_digest :string           not null
#  username        :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#

class Sale < ApplicationRecord
  before_create :set_user_id
  before_save :set_total_amount
  before_validation :set_sale_date

  belongs_to :user
  belongs_to :client
  has_many :payments, through: :sale_items, dependent: :destroy
  has_many :sale_items, dependent: :destroy
  has_many :products, through: :sale_items
  accepts_nested_attributes_for :sale_items, allow_destroy: true

  validates :sale_date, presence: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def set_user_id
    self.user_id ||= Current.user.id if Current.user
  end

  def set_total_amount
    self.total_amount = sale_items.reject(&:marked_for_destruction?).sum do |item|
      (item.quantity || 0) * (item.unit_price || 0)
    end
  end

  def set_sale_date
    if self.sale_date.nil?
      self.sale_date = Date.today
    else
      self.sale_date
    end
  end
end

# == Schema Information
#
# Table name: sales
#
#  id           :integer          not null, primary key
#  observations :text(255)
#  sale_date    :date             not null
#  total_amount :decimal(10, 2)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  client_id    :integer          not null
#  user_id      :integer          not null
#
# Indexes
#
#  index_sales_on_client_id  (client_id)
#  index_sales_on_user_id    (user_id)
#
# Foreign Keys
#
#  client_id  (client_id => clients.id)
#  user_id    (user_id => users.id)
#

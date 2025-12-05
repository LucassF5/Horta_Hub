class Sale < ApplicationRecord
  before_create :set_user_id

  belongs_to :user
  belongs_to :client
  has_many :payments, dependent: :destroy
  has_many :sale_items, dependent: :destroy

  validates :sale_date, presence: true
  validates :payment_status, presence: true
  validates :payment_type, presence: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

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

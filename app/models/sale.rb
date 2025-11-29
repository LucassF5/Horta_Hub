class Sale < ApplicationRecord
  belongs_to :user
  belongs_to :client
  before_create :set_user_id

  validates :sale_date, presence: true
  validates :payment_status, presence: true
  validates :payment_type, presence: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  enum :payment_status, {
    pending: 'pending',
    completed: 'completed',
    failed: 'failed'    
  }

  enum :payment_type, {
    cash: 'cash',
    credit_card: 'credit_card',
    debit_card: 'debit_card',
    pix: 'pix'
  }

end

# == Schema Information
#
# Table name: sales
#
#  id             :integer          not null, primary key
#  observations   :text(255)
#  payment_status :string           not null
#  payment_type   :string           not null
#  sale_date      :date             not null
#  total_amount   :decimal(10, 2)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  client_id      :integer          not null
#  user_id        :integer          not null
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

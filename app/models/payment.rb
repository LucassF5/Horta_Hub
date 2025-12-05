class Payment < ApplicationRecord
  belongs_to :sale

    enum :status, {
    pending: 'pending',
    paid: 'paid',
    failed: 'failed'    
  }

  enum :payment_method, {
    cash: 'cash',
    credit_card: 'credit_card',
    debit_card: 'debit_card',
    pix: 'pix'
  }
end

# == Schema Information
#
# Table name: payments
#
#  id             :integer          not null, primary key
#  amount         :decimal(, )
#  paid_at        :datetime
#  payment_method :string           not null
#  status         :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  sale_id        :integer          not null
#
# Indexes
#
#  index_payments_on_sale_id  (sale_id)
#
# Foreign Keys
#
#  sale_id  (sale_id => sales.id)
#

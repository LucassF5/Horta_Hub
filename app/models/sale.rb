class Sale < ApplicationRecord
  belongs_to :organization
  belongs_to :client
  has_many :sale_items, dependent: :destroy

  accepts_nested_attributes_for :sale_items, allow_destroy: true, reject_if: :all_blank

  enum :status, { pending: "pending", completed: "completed", cancelled: "cancelled" }

  validates :sale_date, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validate :client_must_belong_to_organization

  before_save :calculate_total
  before_validation :normalize_notes

  scope :recent, -> { order(sale_date: :desc) }

  private

  def calculate_total
    self.total = sale_items.reject(&:marked_for_destruction?).sum { |item| item.quantity * item.unit_price }
  end

  def normalize_notes
    return if notes.blank?

    self.notes = notes.strip.squeeze(" ")
  end

  def client_must_belong_to_organization
    return if organization.blank? || client.blank?
    return if client.organization_id == organization_id

    errors.add(:client, "deve pertencer à mesma organização da venda")
  end
end

# == Schema Information
#
# Table name: sales
#
#  id              :integer          not null, primary key
#  notes           :text
#  sale_date       :date             not null
#  status          :string           default("pending"), not null
#  total           :decimal(10, 2)   default(0.0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  client_id       :integer          not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_sales_on_client_id                      (client_id)
#  index_sales_on_organization_id                (organization_id)
#  index_sales_on_organization_id_and_sale_date  (organization_id,sale_date)
#
# Foreign Keys
#
#  client_id        (client_id => clients.id)
#  organization_id  (organization_id => organizations.id)
#

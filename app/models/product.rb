class Product < ApplicationRecord
    extend FriendlyId

    belongs_to :organization
    has_many :sale_items, dependent: :restrict_with_error

    before_save :format_name

    friendly_id :name, use: [ :slugged, :scoped, :history ], scope: :organization

    validates :name, length: { in: 3..50 }, uniqueness: { scope: :organization_id }, presence: true
    validates :price, numericality: { greater_than: 0 }, presence: true
    validates :slug, presence: true, uniqueness: { scope: :organization_id }

    def should_generate_new_friendly_id?
        slug.blank? || (will_save_change_to_name? && !will_save_change_to_slug?)
    end

    private

    def format_name
        self.name = name.downcase.titleize
        Rails.logger.info "Formatted product name to: #{name}"
    end
end

# == Schema Information
#
# Table name: products
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  price           :decimal(10, 2)   not null
#  slug            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_products_on_organization_id_and_slug  (organization_id,slug) UNIQUE
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#

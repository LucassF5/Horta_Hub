class Product < ApplicationRecord
    before_save :format_name

    has_many :sale_items, dependent: :destroy

    validates :name, length: { in: 3..50 }, uniqueness: true, presence: true
    validates :price, numericality: { greater_than: 0 }, presence: true

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
#  id         :integer          not null, primary key
#  name       :string           not null
#  price      :decimal(10, 2)   not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

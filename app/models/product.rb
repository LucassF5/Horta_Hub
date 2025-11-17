class Product < ApplicationRecord
    before_save :format_name

    validates :name, length: { in: 3..50 }, uniqueness: true, presence: true
    validates :price, numericality: { greater_than: 0 }, presence: true

    private

    def format_name
        self.name = name.downcase.titleize
        Rails.logger.info "Formatted product name to: #{name}"
    end
end

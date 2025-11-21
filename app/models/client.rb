class Client < ApplicationRecord

    validates :name, presence: true, length: { minimum: 3, maximum: 30 }
    validates :phone, presence: true, uniqueness: true
    validates :type, presence: true
end

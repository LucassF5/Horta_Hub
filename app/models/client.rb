class Client < ApplicationRecord
    validates :name, presence: true, length: { minimum: 3, maximum: 30 }
    validates :phone, presence: true, uniqueness: true
    validates :type, presence: true
end

# == Schema Information
#
# Table name: clients
#
#  id         :integer          not null, primary key
#  name       :string(65)       not null
#  phone      :string           not null
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

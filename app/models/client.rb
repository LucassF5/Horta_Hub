class Client < ApplicationRecord
    validates :name, presence: true, length: { minimum: 3, maximum: 30 }
    validates :phone, uniqueness: true
    validates :client_type, presence: true

    enum :client_type, {
        pessoa_fisica: "Pessoa Física",
        pessoa_juridica: "Pessoa Jurídica"
    }
end

# == Schema Information
#
# Table name: clients
#
#  id          :integer          not null, primary key
#  name        :string(65)       not null
#  phone       :string
#  client_type :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Client < ApplicationRecord
    belongs_to :organization

    validates :name, presence: true, length: { minimum: 3, maximum: 30 }
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
#  id              :integer          not null, primary key
#  client_type     :string           not null
#  name            :string(65)       not null
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#
